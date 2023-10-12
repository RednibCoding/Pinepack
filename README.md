# Pinepack

Pinepack is a tool designed to streamline the process of building modular web projects using custom HTML components. It enables developers to encapsulate reusable HTML, CSS, and JavaScript within self-contained components. Pinepack recursively replaces custom HTML tags with their corresponding component files, while also extracting and collecting their JavaScript and CSS dependencies.

## Why Pinepack?

Setting up a project with established frontend frameworks like React or Vue often involves a cumbersome setup process that includes installing Node.js, configuring build tools like Webpack, and dealing with a host of other dependencies. This can be a hassle, especially for smaller projects or for developers who are new to the frontend ecosystem.

Pinepack offers a simpler, more streamlined approach to building web applications. Instead of juggling multiple configuration files and a complex build process, Pinepack operates as a standalone compiler.

## Design Goals

The primary design goals for Pinepack are twofold:

1. **Minimalist in Design**: Pinepack aims to offer an extremely user-friendly interface. It eschews intricate configurations and complex setup processes to provide a tool that's as straightforward as possible. With a focus on ease of use, Pinepack wants you to spend less time setting up your development environment and more time coding.

2. **Minimalist in Implementation**: Beyond just being easy to use, Pinepack is designed to be easy to maintain and understand. The codebase is intentionally kept simple, avoiding unnecessary abstractions and complexities. This makes it more sustainable in the long run and easier for contributors to understand and improve upon.

By focusing on these design goals, Pinepack strives to be a valuable tool for both seasoned developers and those new to web development. Whether you are building a small personal project or a large-scale application, Pinepack aims to make the process efficient, enjoyable, and easy to manage.

### What Pinepack Does Differently:

- **Simple Components**: With Pinepack, your components are straightforward HTML files that include their own logic and styles. You don't need a separate package manager or complex build setup to start creating components.
- **Self-Contained Logic and Styles**: Each component is an encapsulated unit with its own HTML, JavaScript, and CSS. This makes each component self-reliant, easy to understand, and easy to test.

- **Standalone Compiler**: Pinepack compiles all of these components into a single, valid HTML, JS, and CSS file. There's no need for npm, Webpack, or any other external tools. This makes the output incredibly portable and easy to distribute.

- **Focus on Simplicity**: Pinepack is built with simplicity in mind, both in terms of the development experience and the final output. This makes it an excellent choice for smaller projects, quick prototypes, or for anyone looking to build a web application without the overhead of a more complex toolchain.

So, if you're looking for a way to build web applications without the complex setup and steep learning curve of traditional frameworks, Pinepack could be the right tool for you.

## Features

- **Component-based Architecture**: Reuse your HTML, CSS, and JS code with ease.
- **Recursive Replacement**: Pinepack will traverse your HTML documents to find and replace all custom components, even those nested within other components.
- **CSS and JS Aggregation**: All CSS and JavaScript code within your components is collected into single CSS and JS files.
- **Namespace Isolation**: Pinepack namespacing isolates your components to avoid styling and scripting conflicts.
- **Cyclic Dependency Checks**: Built-in detection for cyclic dependencies between components.

## Alpha Stage Notice

> **_WARNING:_** **Pinepack is currently in its Alpha stage.** While it is fully functional for a variety of use-cases, please note that some features may still be missing or under development. We're actively working on enhancing its capabilities, and we welcome contributions and feedback from the community.

Feel free to report any issues or suggest new features; your input helps us make Pinepack better for everyone.

## Build from Source

### Prerequisites

- Dart SDK

If you'd like to build Pinepack from the source code, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/RednibCoding/pinepack.git
   ```
2. **Navigate into the Project Folder**:

   ```bash
   cd pinepack
   ```

3. **Get Dart Dependencies**:

   ```bash
   dart pub get
   ```

4. **Build the Project**:

   ```bash
   dart compile exe bin/pinepack.dart -o bin/pinepack
   ```

   This will compile the source code and produce an executable named `pinepack` in the `bin` directory.

5. **Run the Compiled Executable**:

   ```bash
   ./bin/pinepack source_folder
   ```

   This will execute Pinepack with the specified `source_folder`.

   An `index.html` file is expected to exist in the source folder.

   This will create an **_`build`_** folder with the following files:

   - index.html
   - index.js
   - index.css

## Getting Started

Getting started with Pinepack is simple and straightforward. At its core, all you need is a folder containing an `index.html` file.

### Basic index.html

Here's a minimal example of an `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
  </head>

  <body>
    <h1>Hello Pinepack</h1>
  </body>
</html>
```

### Adding a Component

To add a component to your project, you simply write the tag in your HTML file like so:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
  </head>

  <body>
    <my-component />
  </body>
</html>
```

### Component Structure

The content of a typical Pinepack component consists of up to three sections:

- **Template:** The HTML structure of your component.
- **Script:** The JavaScript logic for your component.
- **Style:** The CSS styling for your component.

#### Here's a full component example for `my-component`:

```html
<template>
  <h1 class="title-color">@title</h1>
</template>

<script>
  let title = "Hello from Component my-component";
</script>

<style>
  .title-color {
    color: red;
  }
</style>
```

All code and styles are scoped locally to the component, ensuring that there's no interference with other components—even if they define the same variables or CSS classes.

### Placeholder Syntax

In Pinepack, you can make use of placeholders in your HTML templates to dynamically populate content. Placeholders must be preceded by the `@` symbol and should be single identifiers like variable names or function names. Complex JavaScript expressions are not supported.

For example, in the component template:

```html
<template>
  <h1>@title</h1>
</template>
```

Here, `@title` serves as a placeholder that will be replaced with the value of the title variable defined in the component's script section.
v

```html
<script>
  let title = "Hello from Component my-component";
</script>
```

This allows for a more readable and maintainable structure within your components.

### Organizing Components in Folders

If you prefer to keep your components in a separate folder (let's say a folder named components), you can do so and call them in your main HTML file by mimicking the folder structure in the tag name:

```html
<body>
  <components.my-component />
</body>
```

In the above example, the component `my-component` resides in the components folder. Hence, the tag name uses a dot as a delimiter to indicate the folder path.

## License

This project is licensed under the MIT License.
