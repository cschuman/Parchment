# Code Syntax Highlighting Test

This document tests syntax highlighting for various programming languages.

## Swift Code

```swift
import UIKit

class ViewController: UIViewController {
    private var name: String = "Hello"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let numbers = [1, 2, 3, 4, 5]
        for number in numbers {
            print("Number: \(number)")
        }
        
        if let result = processData() {
            // Handle result
            return result
        }
    }
    
    private func processData() -> String? {
        return "Processed data"
    }
}
```

## JavaScript Code

```javascript
function calculateTotal(items) {
    let total = 0;
    
    for (const item of items) {
        if (item.price && item.quantity) {
            total += item.price * item.quantity;
        }
    }
    
    return total;
}

class ShoppingCart {
    constructor() {
        this.items = [];
        this.discount = 0;
    }
    
    addItem(item) {
        this.items.push(item);
    }
    
    getTotal() {
        const subtotal = calculateTotal(this.items);
        return subtotal * (1 - this.discount);
    }
}

// Usage
const cart = new ShoppingCart();
cart.addItem({ name: "Widget", price: 10.99, quantity: 2 });
console.log("Total:", cart.getTotal());
```

## Python Code

```python
def fibonacci(n):
    """Generate Fibonacci sequence up to n terms"""
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    elif n == 2:
        return [0, 1]
    
    sequence = [0, 1]
    for i in range(2, n):
        sequence.append(sequence[i-1] + sequence[i-2])
    
    return sequence

class Calculator:
    def __init__(self):
        self.history = []
    
    def add(self, a, b):
        result = a + b
        self.history.append(f"{a} + {b} = {result}")
        return result
    
    def get_history(self):
        return self.history

# Example usage
calc = Calculator()
result = calc.add(5, 3)
print(f"Result: {result}")
```

## Plain Code Block

```
This is a plain code block without syntax highlighting.
It should just appear with monospace font and background.

No colors applied here.
```

## Mixed Content

Regular text with inline `code snippets` and then a code block:

```swift
// This should have Swift highlighting
func quickExample() {
    let message = "Syntax highlighting works!"
    print(message)
}
```

More regular text after the code block.