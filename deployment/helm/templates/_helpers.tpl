{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app: spring-example
svc: {{ .Values.spring.serviceName }}
{{- end }}

