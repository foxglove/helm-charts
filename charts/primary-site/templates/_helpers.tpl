{{- define "primary-site.indexingStrategy" -}}
{{- .Values.globals.indexingStrategy | default "split-files" -}}
{{- end -}}

{{- define "primary-site.mergedQueryEngineValues" -}}
{{- mustMerge (.Values.queryEngine | default dict) (.Values.streamService | default dict) | toYaml }}
{{- end -}}
