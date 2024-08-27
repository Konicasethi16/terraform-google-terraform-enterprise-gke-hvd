# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Google cloud storage (GCS) bucket
#------------------------------------------------------------------------------
resource "random_id" "gcs_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "tfe" {
  name                        = "${var.friendly_name_prefix}-tfe-gcs-${random_id.gcs_suffix.hex}"
  location                    = var.gcs_location
  storage_class               = var.gcs_storage_class
  uniform_bucket_level_access = var.gcs_uniform_bucket_level_access
  force_destroy               = var.gcs_force_destroy
  labels                      = var.common_labels

  dynamic "encryption" {
    for_each = var.gcs_kms_cmek_name != null ? ["encryption"] : []

    content {
      default_kms_key_name = data.google_kms_crypto_key.tfe_gcs_cmek[0].id
    }
  }

  versioning {
    enabled = var.gcs_versioning_enabled
  }

  depends_on = [google_kms_crypto_key_iam_binding.gcp_project_gcs_cmek]
}

#------------------------------------------------------------------------------
# KMS Google cloud storage (GCS) customer managed encryption key (CMEK)
#------------------------------------------------------------------------------
data "google_kms_key_ring" "tfe_gcs_cmek" {
  count = var.gcs_kms_keyring_name != null ? 1 : 0

  name     = var.gcs_kms_keyring_name
  location = lower(var.gcs_location)
}

data "google_kms_crypto_key" "tfe_gcs_cmek" {
  count = var.gcs_kms_cmek_name != null ? 1 : 0

  name     = var.gcs_kms_cmek_name
  key_ring = data.google_kms_key_ring.tfe_gcs_cmek[0].id
}