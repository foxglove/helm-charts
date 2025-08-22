{{- define "primary-site.indexingStrategy" -}}
{{- .Values.globals.indexingStrategy | default "split-files" -}}
{{- end -}}

# stream service was renamed to query service.
# some users have values defined under the legacy `streamService` namespace.
# We define defaults in the `queryService` namespace.
# User values in `streamService` should override defaults in `values.yaml` for `queryService`.
{{- define "primary-site.mergedQueryServiceValues" -}}
{{- mustMergeOverwrite (.Values.queryService | default dict) (.Values.streamService | default dict) | toYaml }}
{{- end -}}
