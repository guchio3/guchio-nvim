#!/usr/bin/env python3
"""Test file for LSP configuration."""

import torch  # This should not show error with reportMissingImports = "none"
from typing import Tuple  # This should not show deprecated warning

def example_function(x: int, y: int) -> Tuple[int, int]:
    """Example function with multiple issues on same line."""
    unused_var = 10  # Unused variable
    result = x + y
    # Multiple issues on this line: undefined variable and type issue
    z = undefined_var + "string"  # Multiple errors on same line
    
    return (result, result)

class ExampleClass:
    """Example class for testing."""
    
    def __init__(self):
        self.value = 0
    
    def method_with_warning(self):
        """Method that might have warnings."""
        import os  # Import inside function
        return os.path.exists("/tmp")

# Test cursor-specific diagnostics
if True:
    pass  # No issue here
    print("test")  # No issue here either