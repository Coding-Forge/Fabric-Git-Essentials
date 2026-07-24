#!/usr/bin/env python3
with open('c:\\Projects\\Fabric\\Fabric-BI-DevOps\\tools\\enterprise-standards-builder\\index.html', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    
    # Find the line numbers for key elements
    for i, line in enumerate(lines, 1):
        if 'els.saveToRepo.addEventListener' in line:
            print(f"Save button event listener at line {i}")
        if 'els.copyReport.addEventListener' in line:
            print(f"Copy report listener at line {i}")
        if 'initializeDefaults()' in line:
            print(f"initializeDefaults() at line {i}")
    
    # Calculate bytes up to line 1376
    content_to_1376 = ''.join(lines[:1375])
    bytes_to_1376 = len(content_to_1376.encode('utf-8'))
    print(f"\nBytes to end of line 1375: {bytes_to_1376}")
    print(f"HTTP response size: 50790")
    print(f"Difference: {50790 - bytes_to_1376}")
