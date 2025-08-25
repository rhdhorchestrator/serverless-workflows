"""
Example script with functions to import from SonataFlow workflows
"""

def greet(name):
    """Simple greeting function"""
    return f"Hello, {name}!"

def process_data(data_list):
    """Process a list of data"""
    if not data_list:
        return []
    
    processed = [item.upper() if isinstance(item, str) else str(item) for item in data_list]
    return processed

def calculate_sum(numbers):
    """Calculate sum of numbers"""
    return sum(numbers)

class DataProcessor:
    """Example class for data processing"""
    
    def __init__(self, name):
        self.name = name
    
    def process(self, data):
        """Process data with processor name"""
        return f"Processed by {self.name}: {data}"

# Module-level variable
MODULE_VERSION = "1.0.0"

def workflow_helper(input_data):
    """Helper function specifically for workflow usage"""
    result = {
        "processed": process_data(input_data.get("items", [])),
        "greeting": greet(input_data.get("user", "Anonymous")),
        "version": MODULE_VERSION
    }
    return result
