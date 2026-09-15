# Terraform Built-in Functions

Terraform provides built-in functions that help you transform and work with
values such as strings, lists, maps, and numbers.

## `concat`

The `concat` function combines multiple lists into a single list.

```hcl
variable "list1" {
  type    = list(string)
  default = ["a", "b"]
}

variable "list2" {
  type    = list(string)
  default = ["c", "d"]
}

output "combined_list" {
  value = concat(var.list1, var.list2)
}
```

Output:

```hcl
["a", "b", "c", "d"]
```

## `element`

The `element` function returns the element at the specified index in a list.

```hcl
variable "my_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry"]
}

output "selected_element" {
  value = element(var.my_list, 1)
}
```

Output:

```hcl
"banana"
```

## `length`

The `length` function returns the number of elements in a list.

```hcl
variable "my_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry"]
}

output "list_length" {
  value = length(var.my_list)
}
```

Output:

```hcl
3
```

## `zipmap`

The `zipmap` function creates a map from a list of keys and a list of values.

```hcl
variable "keys" {
  type    = list(string)
  default = ["name", "age"]
}

variable "values" {
  type    = list(string)
  default = ["Alice", "30"]
}

output "my_map" {
  value = zipmap(var.keys, var.values)
}
```

Output:

```hcl
{
  "name" = "Alice"
  "age"  = "30"
}
```

## `lookup`

The `lookup` function retrieves the value associated with a specific key in a
map.

```hcl
variable "my_map" {
  type = map(string)

  default = {
    name = "Alice"
    age  = "30"
  }
}

output "value" {
  value = lookup(var.my_map, "name")
}
```

Output:

```hcl
"Alice"
```
