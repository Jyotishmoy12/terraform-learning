provider "aws" {
  region = "us-east-1"
}


# Vault is used to store secrets and sensitive information

provider "vault" {
  address          = "<>8200" # why do write address as <>8200?  This means that the vault server is running on localhost at port 8200. The <> is a placeholder for the actual address of the vault server.
  skip_child_token = true     # why do you mean by skip_child_token?  This means that the provider will not attempt to create a child token for the Vault provider. This is useful if you are using a root token or a token with sufficient privileges to access the secrets you need.

  auth_login {
    path = "auth/approle/login" # This is the path to the AppRole authentication method in Vault. It is used to authenticate and obtain a token for accessing secrets.

    parameters = {
      role_id   = "<role_id>"   # This is the role ID for the AppRole authentication method. It is used to identify the role that the client is trying to authenticate with.
      secret_id = "<secret_id>" # This is the secret ID for the AppRole authentication method. It is used to authenticate and obtain a token for accessing secrets.
    }
  }
}

resource "aws_instance" "example" {
  ami           = "ami-xxjllttktk"
  instance_type = "t2.micro"

  tags = {
    Name   = "test"
    Secret = data.vault_kv_secret_v2.example.data["foo"]
  }
}

