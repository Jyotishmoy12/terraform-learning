# Terraform Variables

Input and output variables in Terraform are essential for parameterizing and
sharing values within Terraform configurations and modules. They make your
configuration more dynamic, reusable, and flexible.

## Input Variables

Input variables are used to parameterize Terraform configurations. They allow
you to pass values into your modules or configurations from the outside.

Input variables can be defined inside a module or at the root level of your
configuration.

### Example

```hcl
variable "example_var" {
  description = "An example input variable"
  type        = string
  default     = "default_value"
}
```

In this example:

1. `variable` is used to declare an input variable named `example_var`.
2. `description` provides a human-readable description of the variable.
3. `type` specifies the data type of the variable, such as `string`, `number`,
   `list`, or `map`.
4. `default` provides an optional default value for the variable.

You can use the input variable inside your module or configuration like this:

```hcl
resource "example_resource" "example" {
  name = var.example_var
}
```

You reference the input variable using `var.example_var`.

## Output Variables

Output variables allow you to expose values from your module or configuration.
These values can then be used in other parts of your Terraform setup.

### Example

```hcl
output "example_output" {
  description = "An example output variable"
  value       = example_resource.example.id
}
```

In this example:

1. `output` is used to declare an output variable named `example_output`.
2. `description` provides a description of the output variable.
3. `value` specifies the value that you want to expose as an output variable.
   This value can be a resource attribute, a computed value, or any other
   Terraform expression.

You can reference output variables from another module using this syntax:

```hcl
module.module_name.output_name
```

Here, `module_name` is the name of the module containing the output variable.

## Running Terraform with Variables

When a Terraform configuration has input variables without default values, you
must pass values for those variables when running Terraform commands.

### Plan

Use `terraform plan` to preview the changes Terraform will make:

```powershell
terraform plan -var="ami_id=ami-0354c98ae10b02961" -var="instance_type=t2.micro"
```

### Apply

Use `terraform apply` to create the resources:

```powershell
terraform apply -var="ami_id=ami-0354c98ae10b02961" -var="instance_type=t2.micro"
```

### Destroy

Use `terraform destroy` to delete the resources:

```powershell
terraform destroy -var="ami_id=ami-0354c98ae10b02961" -var="instance_type=t2.micro"
```
