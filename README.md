# LibSettings

LibSettings is an API wrapper designed to simplify the process of creating settings layouts in World of Warcraft. It leverages the native Settings API provided by the game, but is considerably less verbose when defining and managing settings. 

## Functions

### Create(props, owner, layout)

This function creates a new settings object with the given properties, owner, and layout. It registers the created object in the add-on category and stores it in the registry.

**Parameters:**

- `props`: The properties of the settings object.
- `owner`: The owner of the settings object.
- `layout`: The layout of the settings object.

**Returns:**

- The created settings object.

### Add(props, owner, layout)

This function creates a new settings object with the given properties, owner, and layout.

**Parameters:**

- `props`: The properties of the settings object.
- `owner`: The owner of the settings object.
- `layout`: The layout of the settings object.

**Returns:**

- The created settings object.

### LoadAddOnCategory(name, generator, callback)

This function loads a category from an add-on. It waits until the add-on is loaded before creating the category, allowing saved variables to be loaded first.

**Parameters:**

- `name`: The name of the add-on to load settings for.
- `generator`: A function to generate a props tree.
- `callback`: An optional function to call when the category is created.

### AppendAddOnCategory(name, generator, callback)

This function appends more settings to an add-on category. It waits until the add-on is loaded before creating the category, allowing saved variables to be loaded first.

**Parameters:**

- `name`: The name of the add-on to observe.
- `generator`: A function to generate an appendage props tree.
- `callback`: An optional function to call when the appendage is created.

### Get(id)

This function retrieves a widget tree from the registry by its unique identifier.

**Parameters:**

- `id`: The unique identifier of the widget tree.

**Returns:**

- The widget tree from the registry.

## Properties

### Registry

This property is a table that stores all the created settings objects.

### Types

This property is an enumeration of available widget and category types.

### Factory

This property holds factory functions for each of the available widget and category types.