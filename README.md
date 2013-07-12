# Mammouth - Unfancy PHP #
Mammouth is a small language that compiles into PHP, inspired by CoffeeScript. It's compiled to PHP codes/files that you can run in your PHP server.

## Installation ##
Via npm:
```
npm install mammouth
```

## Usage ##
Once installed, you should have access to the coffee command, which can execute scripts, compile `.mammouth` files into `.php`. The coffee command takes the following options: 
```
Usage: mammouth [options] [dir|file ...]

Options:
  -c, --compile        Compile a ".mammouth"  or  into a .php file of the same name(can compiles a folder).
  -o, --output [DIR]   Write out all compiled PHP files into the specified directory. Use in conjunction with --compile

Examples:

  # Compile 'codes.mammouth' to 'codes.php' in the same folder
  $ mammouth --compile codes.mammouth

  # Compile all mammouth files in 'codes' folder to 'result' folder
  $ mammouth --compile --output /result /codes
```

You can compile mammouth script from browser by adding `mammouth.js` in `/extras` to your html page, and call compile function:
```javascript
mammouth.compile("<your mammouth code as string>")
```