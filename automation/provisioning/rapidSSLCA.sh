#!/usr/bin/env bash
scriptName='rapidSSLCA.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	uname -a
	centos=$(uname -a | grep el)
	
	if [ -z "$centos" ]; then
		store='/etc/ssl/certs/ca-certificates.crt'
		echo "[$scriptName]   store : $store (default for git/curl for Ubuntu)"
	else
		store='/etc/pki/tls/certs/ca-bundle.crt'
		echo "[$scriptName]   store : $store (default for git/curl) for CentOS"
	fi
else
	store="$1"
	echo "[$scriptName]   store : $store"
fi

echo "[$scriptName] Install CA to $store"

sudo sh -c "echo \# GeoTrustGlobalCA via $scriptName provisioning script.>> $store"
sudo sh -c "echo -----BEGIN CERTIFICATE----->> $store"
sudo sh -c "echo MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT>> $store"
sudo sh -c "echo MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i>> $store"
sudo sh -c "echo YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG>> $store"
sudo sh -c "echo EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg>> $store"
sudo sh -c "echo R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9>> $store"
sudo sh -c "echo 9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq>> $store"
sudo sh -c "echo fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv>> $store"
sudo sh -c "echo iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU>> $store"
sudo sh -c "echo 1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+>> $store"
sudo sh -c "echo bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW>> $store"
sudo sh -c "echo MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA>> $store"
sudo sh -c "echo ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l>> $store"
sudo sh -c "echo uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn>> $store"
sudo sh -c "echo Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS>> $store"
sudo sh -c "echo tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF>> $store"
sudo sh -c "echo PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un>> $store"
sudo sh -c "echo hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV>> $store"
sudo sh -c "echo 5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==>> $store"
sudo sh -c "echo -----END CERTIFICATE----->> $store"

sudo sh -c "echo \# RapidSSLSHA256CA-G3 \(intermediate\) via $scriptName provisioning script.>> $store"
sudo sh -c "echo -----BEGIN CERTIFICATE----->> $store"
sudo sh -c "echo MIIEJTCCAw2gAwIBAgIDAjp3MA0GCSqGSIb3DQEBCwUAMEIxCzAJBgNVBAYTAlVT>> $store"
sudo sh -c "echo MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i>> $store"
sudo sh -c "echo YWwgQ0EwHhcNMTQwODI5MjEzOTMyWhcNMjIwNTIwMjEzOTMyWjBHMQswCQYDVQQG>> $store"
sudo sh -c "echo EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEgMB4GA1UEAxMXUmFwaWRTU0wg>> $store"
sudo sh -c "echo U0hBMjU2IENBIC0gRzMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCv>> $store"
sudo sh -c "echo VJvZWF0eLFbG1eh/9H0WA//Qi1rkjqfdVC7UBMBdmJyNkA+8EGVf2prWRHzAn7Xp>> $store"
sudo sh -c "echo SowLBkMEu/SW4ib2YQGRZjEiwzQ0Xz8/kS9EX9zHFLYDn4ZLDqP/oIACg8PTH2lS>> $store"
sudo sh -c "echo 1p1kD8mD5xvEcKyU58Okaiy9uJ5p2L4KjxZjWmhxgHsw3hUEv8zTvz5IBVV6s9cQ>> $store"
sudo sh -c "echo DAP8m/0Ip4yM26eO8R5j3LMBL3+vV8M8SKeDaCGnL+enP/C1DPz1hNFTvA5yT2AM>> $store"
sudo sh -c "echo QriYrRmIV9cE7Ie/fodOoyH5U/02mEiN1vi7SPIpyGTRzFRIU4uvt2UevykzKdkp>> $store"
sudo sh -c "echo YEj4/5G8V1jlNS67abZZAgMBAAGjggEdMIIBGTAfBgNVHSMEGDAWgBTAephojYn7>> $store"
sudo sh -c "echo qwVkDBF9qn1luMrMTjAdBgNVHQ4EFgQUw5zz/NNGCDS7zkZ/oHxb8+IIy1kwEgYD>> $store"
sudo sh -c "echo VR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAQYwNQYDVR0fBC4wLDAqoCig>> $store"
sudo sh -c "echo JoYkaHR0cDovL2cuc3ltY2IuY29tL2NybHMvZ3RnbG9iYWwuY3JsMC4GCCsGAQUF>> $store"
sudo sh -c "echo BwEBBCIwIDAeBggrBgEFBQcwAYYSaHR0cDovL2cuc3ltY2QuY29tMEwGA1UdIARF>> $store"
sudo sh -c "echo MEMwQQYKYIZIAYb4RQEHNjAzMDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdlb3Ry>> $store"
sudo sh -c "echo dXN0LmNvbS9yZXNvdXJjZXMvY3BzMA0GCSqGSIb3DQEBCwUAA4IBAQCjWB7GQzKs>> $store"
sudo sh -c "echo rC+TeLfqrlRARy1+eI1Q9vhmrNZPc9ZE768LzFvB9E+aj0l+YK/CJ8cW8fuTgZCp>> $store"
sudo sh -c "echo fO9vfm5FlBaEvexJ8cQO9K8EWYOHDyw7l8NaEpt7BDV7o5UzCHuTcSJCs6nZb0+B>> $store"
sudo sh -c "echo kvwHtnm8hEqddwnxxYny8LScVKoSew26T++TGezvfU5ho452nFnPjJSxhJf3GrkH>> $store"
sudo sh -c "echo uLLGTxN5279PURt/aQ1RKsHWFf83UTRlUfQevjhq7A6rvz17OQV79PP7GqHQyH5O>> $store"
sudo sh -c "echo ZI3NjGFVkP46yl0lD/gdo0p0Vk8aVUBwdSWmMy66S6VdU5oNMOGNX2Esr8zvsJmh>> $store"
sudo sh -c "echo gP8L8mJMcCaY>> $store"
sudo sh -c "echo -----END CERTIFICATE----->> $store"

tail -47 $store
echo "[$scriptName] --- end ---"
