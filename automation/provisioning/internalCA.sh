#!/usr/bin/env bash
scriptName='internalCA.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	store='/etc/ssl/certs/ca-certificates.crt'
	echo "[$scriptName]   store : $store (default)"
else
	store="$1"
	echo "[$scriptName]   store : $store"
fi

echo "[$scriptName] Install CA to $store"

sudo sh -c "echo -----BEGIN CERTIFICATE----->> $store"
sudo sh -c "echo MIIDoTCCAomgAwIBAgIQLIaJcxhmob9KbXjpW04V+zANBgkqhkiG9w0BAQUFADBX>> $store"
sudo sh -c "echo MRMwEQYKCZImiZPyLGQBGRYDbmV0MRYwFAYKCZImiZPyLGQBGRYGd2ViaG9wMRMw>> $store"
sudo sh -c "echo EQYKCZImiZPyLGQBGRYDaGRjMRMwEQYDVQQDEwpIREMtSU5GLUNBMB4XDTE2MDMw>> $store"
sudo sh -c "echo NTIzMTAwNloXDTIxMDMwNTIzMjAwNFowVzETMBEGCgmSJomT8ixkARkWA25ldDEW>> $store"
sudo sh -c "echo MBQGCgmSJomT8ixkARkWBndlYmhvcDETMBEGCgmSJomT8ixkARkWA2hkYzETMBEG>> $store"
sudo sh -c "echo A1UEAxMKSERDLUlORi1DQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB>> $store"
sudo sh -c "echo AMzES1zMpE173gPHPktqndlSXNjo17qlGMznWX6KylT0ufxAZHG1OMHsU6ef4ZRN>> $store"
sudo sh -c "echo RQ3h3zLrhmCgwxTrBbvYhHWGpvgtIu3+p+e5s+VZ3vwdICRN2n2S2NrDCsh+h+XH>> $store"
sudo sh -c "echo XQjkpnrt18uCmN8qEXikjLV84XdiFK5VwqQGuzrxvWG/1M2tNUUi81TAABmfFJNc>> $store"
sudo sh -c "echo toRrZUEc17nBT7Kb/PJKaFB00MixjN9n8FhpoaKUKLQZLQCSmSC+rDKuY/oZRgE8>> $store"
sudo sh -c "echo 4ihbu62jJiviPaEAoEcTQrhMZPJbAqMGyMUGapbLr5kW5iomPFz3MNNE3UP0mRU9>> $store"
sudo sh -c "echo hhrsayOFSbZdKuxyvUzgUAECAwEAAaNpMGcwEwYJKwYBBAGCNxQCBAYeBABDAEEw>> $store"
sudo sh -c "echo DgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMR+Bqo4>> $store"
sudo sh -c "echo IaxV+6j5mxiW9RSAkv/DMBAGCSsGAQQBgjcVAQQDAgEAMA0GCSqGSIb3DQEBBQUA>> $store"
sudo sh -c "echo A4IBAQDDuP+1phVeMNqLSo062Z6RiZ31JRW9zjoRk8RdOQtO9lHy7HngFGWLTkQR>> $store"
sudo sh -c "echo ZKquy0rzqIV1jlR2HoIzKkRUVRHjfZiuNrhj22TesBxOpcfLWODT2S8dtWeeaJqj>> $store"
sudo sh -c "echo ENfCbg1ewnQYJbXstor03saIj0OLlArkzp12KRGKdjTcSbFUwxdhOvTAUErvYB/a>> $store"
sudo sh -c "echo xwBFhhPeERdil+zlUrOje7ySI1W20U0e5rGSJvTPEydO/V9KvhfrOlFkgIXqRRzq>> $store"
sudo sh -c "echo sH4+gtQY20hUOLBnZVGQrQusSRo0dGXA9MA/5CqhX5yUkCy/tVsxFGEQaKsQJuKZ>> $store"
sudo sh -c "echo WV3Ywu1TrydSRHAzKAI2Lm5b7qzE>> $store"
sudo sh -c "echo -----END CERTIFICATE----->> $store"

echo "[$scriptName] --- end ---"
