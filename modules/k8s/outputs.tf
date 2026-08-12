output "namespace" {
  value = kubernetes_namespace.retail_app.metadata[0].name
}
