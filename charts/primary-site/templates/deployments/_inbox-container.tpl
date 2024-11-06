{{- define "primary-site.inbox-container" }}
template:
  metadata:
    labels:
      app: inbox-listener
      {{- range $key, $value := .Values.inboxListener.deployment.podLabels }}
      {{ $key }}: {{ $value | quote }}
      {{- end }}
    annotations:
      {{- range $key, $value := .Values.inboxListener.deployment.podAnnotations }}
      {{ $key }}: {{ $value | quote }}
      {{- end }}
  spec:
    volumes:
      - name: cloud-credentials
        secret:
          secretName: gcp-cloud-credential
          optional: true
      {{- if .Values.inboxListener.deployment.localScratch.enabled }}
      - name: local-scratch
        emptyDir:
          sizeLimit: {{ .Values.inboxListener.deployment.localScratch.capacityBytes }}
      {{- end }}
    {{- if .Values.inboxListener.deployment.nodeSelectors }}
    nodeSelector:
          {{- range $key, $value := .Values.inboxListener.deployment.nodeSelectors }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
        {{- end}}
    {{- if .Values.inboxListener.deployment.serviceAccount.enabled }}
    serviceAccount: inbox-listener
    {{- end}}
    containers:
      - name: inbox-listener
        image: us-central1-docker.pkg.dev/foxglove-images/images/inbox-listener:{{ .Chart.AppVersion }}
        resources:
          requests:
            cpu: {{ .Values.inboxListener.deployment.resources.requests.cpu }}
            memory: {{ .Values.inboxListener.deployment.resources.requests.memory }}
            {{- if .Values.inboxListener.deployment.localScratch.enabled }}
            ephemeral-storage: {{ .Values.inboxListener.deployment.localScratch.capacityBytes }}
            {{- end}}
          limits:
            cpu: {{ .Values.inboxListener.deployment.resources.limits.cpu }}
            memory: {{ .Values.inboxListener.deployment.resources.limits.memory }}
            {{- if .Values.inboxListener.deployment.localScratch.enabled }}
            ephemeral-storage: {{ .Values.inboxListener.deployment.localScratch.capacityBytes }}
            {{- end}}
        volumeMounts:
          - mountPath: /secrets
            name: cloud-credentials
          {{- if .Values.inboxListener.deployment.localScratch.enabled }}
          - mountPath: /local-scratch
            name: local-scratch
          {{- end }}
        ports:
          - name: metrics
            containerPort: 6001
        envFrom:
          - secretRef:
              name: cloud-credentials
              optional: true
          - secretRef:
              name: foxglove-site-token
              optional: true
          {{- range $k := .Values.globals.secrets }}
          - secretRef:
              name: {{ $k }}
          {{- end }}
        env:
          {{ with lookup "v1" "Secret" .Release.Namespace "gcp-cloud-credential" }}
          ## The lookup is required here. The pod may have access to GCP through other means, but
          ## the credentials in this env var take precedence, even if it's empty. An empty variable
          ## essentially blocks GCP access.
          - name: GOOGLE_APPLICATION_CREDENTIALS
            value: /secrets/credentials.json
          {{ end }}
          - name: FOXGLOVE_API_URL
            value: "{{ .Values.globals.foxgloveApiUrl }}"
          {{- if .Values.globals.siteToken }}
          - name: FOXGLOVE_SITE_TOKEN
            valueFrom:
              secretKeyRef:
                name: foxglove-site
                key: token
                optional: false
          {{- end }}
          - name: MODE
            value: self-managed
          - name: INBOX_STORAGE_PROVIDER
            value: "{{ .Values.globals.inbox.storageProvider }}"
          - name: STORAGE_INBOX_BUCKET_NAME
            value: "{{ .Values.globals.inbox.bucketName }}"
          - name: LAKE_STORAGE_PROVIDER
            value: "{{ .Values.globals.lake.storageProvider }}"
          - name: STORAGE_LAKE_BUCKET_NAME
            value: "{{ .Values.globals.lake.bucketName }}"
          - name: STORAGE_AZURE_STORAGE_ACCOUNT_NAME
            value: "{{ .Values.globals.azure.storageAccountName }}"
          - name: STORAGE_AZURE_SERVICE_URL
            value: "{{ .Values.globals.azure.serviceUrl }}"
          - name: AWS_REGION
            value: "{{ .Values.globals.aws.region }}"
          - name: AWS_SDK_LOAD_CONFIG
            value: "true"
          - name: PROMETHEUS_METRICS_NAMESPACE
            value: "{{ .Values.inboxListener.deployment.metrics.namespace }}"
          - name: PROMETHEUS_METRICS_SUBSYSTEM
            value: "{{ .Values.inboxListener.deployment.metrics.subsystem }}"
          - name: PRIMARY_SITE_VERSION
            value: "{{ .Chart.Version }}"
          {{- range $item := .Values.inboxListener.deployment.env }}
          - name: {{ $item.name }}
            value: {{ $item.value | quote}}
          {{- end }}
          {{- if .Values.inboxListener.autoscaling.enabled }}
          - name: MAX_WAIT_FOR_WORK
            value: {{ .Values.inboxListener.autoscaling.maxWaitForWork }}
          {{- end }}
          {{- if .Values.inboxListener.deployment.localScratch.enabled }}
          - name: LOCAL_SCRATCH_ROOT
            value: "/local-scratch"
          - name: LOCAL_SCRATCH_CAPACITY_BYTES
            value: "{{ .Values.inboxListener.deployment.localScratch.capacityBytes }}"
          {{- end }}
{{- end -}}
