# Test decorator support
def route(path):
    def decorator(func):
        print("Route: " + path + " -> " + func.__name__)
        return func
    return decorator

@route('/')
def hello():
    return "Hello"

result = hello()
print(result)

# Test classes with methods
class App:
    def __init__(self, name):
        self.name = name

    def run(self):
        print("Running " + self.name)

app = App("test")
app.run()
