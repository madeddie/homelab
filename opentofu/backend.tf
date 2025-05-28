variable "state_passphrase" {
  type = string
}

terraform {
  encryption {
    key_provider "pbkdf2" "key" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "method" {
      keys = key_provider.pbkdf2.key
    }

    state {
      method = method.aes_gcm.method
      enforced = true
    }
  }
}
