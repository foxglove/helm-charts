{{- define "primary-site.indexingStrategy" -}}
{{- .Values.globals.indexingStrategy | default "split-files" -}}
{{- end -}}

# stream service was renamed to query engine.
# some users have values defined under the legacy `streamService` namespace.
# We define defaults in the `queryEngine` namespace.
# User values in `streamService` should override defaults in `values.yaml` for `queryEngine`.
{{- define "primary-site.mergedQueryEngineValues" -}}
{{- mustMergeOverwrite (.Values.queryEngine | default dict) (.Values.streamService | default dict) | toYaml }}
{{- end -}}
