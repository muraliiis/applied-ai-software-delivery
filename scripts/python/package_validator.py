#!/usr/bin/env python3
"""
Package Validator - Validates Shopz package integrity and contents
Usage: python package_validator.py <package_file>
"""

import sys
import os
import hashlib
import re
from pathlib import Path
from typing import Dict, List, Tuple


class PackageValidator:
    """Validates z/OS software packages"""
    
    def __init__(self, package_path: str):
        self.package_path = Path(package_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: Dict[str, any] = {}
        
    def validate(self) -> bool:
        """Run all validation checks"""
        print(f"Validating package: {self.package_path}")
        print("=" * 60)
        
        # Check 1: File exists
        if not self._check_file_exists():
            return False
            
        # Check 2: File size
        self._check_file_size()
        
        # Check 3: Calculate checksum
        self._calculate_checksum()
        
        # Check 4: Package naming convention
        self._check_naming_convention()
        
        # Print results
        self._print_results()
        
        return len(self.errors) == 0
        
    def _check_file_exists(self) -> bool:
        """Check if package file exists"""
        if not self.package_path.exists():
            self.errors.append(f"Package file not found: {self.package_path}")
            return False
        self.info['exists'] = True
        return True
        
    def _check_file_size(self) -> None:
        """Check package file size"""
        size_bytes = self.package_path.stat().st_size
        size_mb = size_bytes / (1024 * 1024)
        
        self.info['size_bytes'] = size_bytes
        self.info['size_mb'] = round(size_mb, 2)
        
        if size_bytes == 0:
            self.errors.append("Package file is empty (0 bytes)")
        elif size_mb < 1:
            self.warnings.append(f"Package size is unusually small: {size_mb:.2f} MB")
        elif size_mb > 10000:
            self.warnings.append(f"Package size is very large: {size_mb:.2f} MB")
            
    def _calculate_checksum(self) -> None:
        """Calculate MD5 and SHA256 checksums"""
        print("Calculating checksums... ", end='', flush=True)
        
        md5_hash = hashlib.md5()
        sha256_hash = hashlib.sha256()
        
        with open(self.package_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                md5_hash.update(chunk)
                sha256_hash.update(chunk)
                
        self.info['md5'] = md5_hash.hexdigest()
        self.info['sha256'] = sha256_hash.hexdigest()
        print("Done")
        
    def _check_naming_convention(self) -> None:
        """Validate package naming follows Shopz convention"""
        filename = self.package_path.name
        
        # Expected pattern: S1234567.pax.Z or similar
        pattern = r'^S\d{7}\.(pax\.Z|tar\.Z|bin)$'
        
        if not re.match(pattern, filename):
            self.warnings.append(
                f"Package name doesn't follow Shopz convention: {filename}"
            )
        else:
            # Extract order number
            order_num = filename.split('.')[0]
            self.info['order_number'] = order_num
            
    def _print_results(self) -> None:
        """Print validation results"""
        print("\n" + "=" * 60)
        print("VALIDATION RESULTS")
        print("=" * 60)
        
        # Print info
        print("\n📦 Package Information:")
        print(f"  File: {self.package_path.name}")
        if 'order_number' in self.info:
            print(f"  Order Number: {self.info['order_number']}")
        print(f"  Size: {self.info['size_mb']} MB ({self.info['size_bytes']:,} bytes)")
        print(f"  MD5: {self.info['md5']}")
        print(f"  SHA256: {self.info['sha256']}")
        
        # Print warnings
        if self.warnings:
            print(f"\n⚠️  Warnings ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  - {warning}")
                
        # Print errors
        if self.errors:
            print(f"\n❌ Errors ({len(self.errors)}):")
            for error in self.errors:
                print(f"  - {error}")
        else:
            print("\n✅ All validation checks passed!")
            
        print("=" * 60)


def main():
    """Main entry point"""
    if len(sys.argv) != 2:
        print("Usage: python package_validator.py <package_file>")
        print("Example: python package_validator.py /tmp/packages/S1234567.pax.Z")
        sys.exit(1)
        
    package_file = sys.argv[1]
    
    validator = PackageValidator(package_file)
    success = validator.validate()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
