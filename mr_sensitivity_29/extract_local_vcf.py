"""Offline streaming extraction. No network access. ALT is the effect allele."""
import csv, gzip, hashlib, json
from pathlib import Path
O=Path(__file__).resolve().parent
wanted={r['SNP'] for r in csv.DictReader((O/'instruments_all.csv').open(encoding='utf-8-sig'))}
fields=['rsid','chr','position','ea','nea','beta','se','LP','eaf','n','id']
audit=[]
for oid in ['finn-b-I9_IHD','finn-b-F5_DEPRESSIO']:
    path=O/'PRIVATE_NOT_FOR_ARCHIVE'/'official_vcf'/f'{oid}.vcf.gz'
    sha=hashlib.file_digest(path.open('rb'),'sha256').hexdigest()
    matched=[]; headers=[]; total=0
    with gzip.open(path,'rt') as handle:
        for line in handle:
            if line.startswith('#'):
                headers.append(line)
                continue
            total+=1
            chrom,pos,ids,rest=line.split('\t',3)
            hits=wanted.intersection(ids.split(';'))
            if not hits: continue
            ref,alt,qual,filt,info,fmt,sample=rest.rstrip('\n').split('\t')
            if ',' in alt: raise ValueError(f'Multiallelic selected record: {oid} {ids}')
            if filt not in ['PASS','.']: raise ValueError(f'Filtered selected record: {oid} {ids}')
            values=dict(zip(fmt.split(':'),sample.split(':')))
            for key in ['ES','SE','LP','AF']:
                if ',' in values.get(key,''): raise ValueError(f'Multiple FORMAT values: {oid} {ids}')
            for rsid in sorted(hits):
                matched.append(dict(zip(fields,[rsid,chrom,pos,alt,ref,values.get('ES','.'),values.get('SE','.'),values.get('LP','.'),values.get('AF','.'),values.get('SS','.'),oid])))
    counts={}
    for row in matched: counts[row['rsid']]=counts.get(row['rsid'],0)+1
    duplicates={k for k,v in counts.items() if v>1}
    # Ambiguous rsID mappings are excluded in full, rather than choosing a row.
    valid=[r for r in matched if r['rsid'] not in duplicates]
    for suffix,rows in [('selected',valid),('ambiguous', [r for r in matched if r['rsid'] in duplicates])]:
        with (O/f'{oid}_{suffix}.csv').open('w',newline='',encoding='utf-8') as h:
            writer=csv.DictWriter(h,fieldnames=fields);writer.writeheader();writer.writerows(rows)
    (O/'PRIVATE_NOT_FOR_ARCHIVE'/f'{oid}_header.txt').write_text(''.join(headers),encoding='utf-8')
    missing=sorted(wanted-set(counts))
    (O/f'{oid}_missing_snps.txt').write_text('\n'.join(missing),encoding='utf-8')
    audit.append(dict(id=oid,sha256=sha,bytes=path.stat().st_size,records_scanned=total,requested_unique_snps=len(wanted),matched_unique_snps=len(counts),ambiguous_rsids=len(duplicates),retained_unique_snps=len(valid),missing_snps=len(missing)))
    print(audit[-1],flush=True)
(O/'vcf_extraction_audit.json').write_text(json.dumps(audit,indent=2),encoding='utf-8')
