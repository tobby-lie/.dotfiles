#!/usr/bin/env python3
import os
import sys

def generate_cpp_template(filename):
    """
    Generates a C++ template file for competitive programming.
    
    Args:
        filename (str): Name of the file to create (with or without .cpp extension)
    
    Returns:
        bool: True if file was created successfully, False otherwise
    """
    # Ensure the filename has .cpp extension
    if not filename.endswith('.cpp'):
        filename += '.cpp'
    
    # Check if file already exists
    if os.path.exists(filename):
        print(f"Error: File '{filename}' already exists.")
        return False
    
    # Template content with optimized I/O
    template = '''#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

void solve() {
    
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    
    int t;
    cin >> t;
    while (t--)
        solve();
    return 0;
}
'''
    
    try:
        # Create the file and write the template
        with open(filename, 'w') as f:
            f.write(template)
        
        # Make the file executable on Unix-like systems
        if os.name == 'posix':
            current_permissions = os.stat(filename).st_mode
            os.chmod(filename, current_permissions | 0o100)
        
        print(f"Successfully created '{filename}'")
        return True
        
    except IOError as e:
        print(f"Error creating file: {e}")
        return False

def main():
    # Check if filename was provided
    if len(sys.argv) != 2:
        print("Usage: python cp_init.py <filename>")
        print("Example: python cp_init.py problem1")
        sys.exit(1)
    
    filename = sys.argv[1]
    generate_cpp_template(filename)

if __name__ == "__main__":
    main()
