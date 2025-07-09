{{- define "primary-site.indexingStrategy" -}}
{{- .Values.globals.indexingStrategy | default "split-files" -}}
{{- end -}}
