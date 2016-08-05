require 'sneakers'
require 'sneakers/metrics/logging_metrics'

log = Rails.root.join("log", Setting.sneakers["log"] || "sneakers.log")
runner_config = Rails.root.join("config", Setting.sneakers["runner_config_file"]).to_s if Setting.sneakers["runner_config_file"]

pid_path = Rails.root.join("tmp", "pids", Setting.sneakers["pid_path"] || "sneakers.pid")
tls_cert = Rails.root.join("config", Setting.sneakers["tls_cert"]).to_s
tls_key = Rails.root.join("config", Setting.sneakers["tls_key"]).to_s
tls_ca_certificates = Setting.sneakers["tls_ca_certificates"].map { |ca_cert| Rails.root.join("config", ca_cert).to_s }

Sneakers.configure(Setting.sneakers.symbolize_keys.merge(log: log, pid_path: pid_path, tls_cert: tls_cert, tls_key: tls_key, tls_ca_certificates: tls_ca_certificates, metrics: Sneakers::Metrics::LoggingMetrics.new, runner_config_file: runner_config))
Sneakers.logger.level = Logger::WARN if Rails.env.production?
