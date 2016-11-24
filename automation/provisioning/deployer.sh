#!/usr/bin/env bash
scriptName='deployer.sh'

echo "[$scriptName] --- start ---"
deployerSide='server'
if [ -z "$deployerSide" ]; then
	echo "[$scriptName]   deployerSide : $deployerSide (default, choices server, target or hop)"
else
	deployerSide="$1"
	echo "[$scriptName]   deployerSide : $deployerSide (choices server or target)"
fi

if [ -z "$2" ]; then
	deployUser='deployer'
	echo "[$scriptName]   deployUser   : $deployUser (default)"
else
	deployUser="$2"
	echo "[$scriptName]   deployUser   : $deployUser"
fi

if [ -z "$3" ]; then
	deployLand='/opt/packages/'
	echo "[$scriptName]   deployLand   : $deployLand (default)"
else
	deployLand="$3"
	echo "[$scriptName]   deployLand   : $deployLand"
fi

if [ -z "$3" ]; then
	echo "[$scriptName]   group        : not supplied"
else
	group="$3"
	echo "[$scriptName]   group        : $group"
fi

if [ "$deployerSide" == 'server' ] || [ "$deployerSide" == 'hop' ]; then

	echo "[$scriptName] Prepare vagrant user keys"

	if [ "$deployerSide" == 'hop' ]; then
		runAsUser="${deployUser}"
	else
		runAsUser='vagrant'
	fi

# cannot indent or EOF will not be detected
su ${runAsUser} << EOF

	# Escape variables that need to be executed as ${runAsUser}
	echo "[$scriptName] Install private key for both SSL (password decrypt) and SSH to \${HOME}"
	userSSL="\${HOME}/.ssl"
	if [ -d "\$userSSL" ]; then
		echo "[$scriptName] User SSL directory (\$userSSL) exists, no action required"
	else
		echo "[$scriptName] Create user SSL directory (\$userSSL)"
		mkdir \$userSSL
	fi
	echo "[$scriptName] Install private key to \$userSSH/private_key.pem"
	
	echo "-----BEGIN RSA PRIVATE KEY-----" >> \$userSSL/private_key.pem
	echo "MIIEpAIBAAKCAQEA6AM/oCp+j+KfYHMvf/mHFZp+TfTYE/j5g0Xw11cEpSevgLM1" >> \$userSSL/private_key.pem
	echo "d+rDxPjh5SE9gp0iCqrbbQL9o0DYAvw1DtQRH6e7H77vfm4NPAZSVxTtjQq2bWnd" >> \$userSSL/private_key.pem
	echo "6xisu6xJxmJi+FEAwyf2uRzwUo0cfaCIN3SEaf9gGaZ0Ze0/+u8aT6MlsBCcZuby" >> \$userSSL/private_key.pem
	echo "/F76pHBGMfxJiIvkD/EUHfoasP8C9QlGzncXYMIV/YTIDjSya7kZHIw7VKaATdaJ" >> \$userSSL/private_key.pem
	echo "TZVLbavQ6FTTQMlL7PJreazFC1A0NO/+5DcErnDg/VyywTezxAWo1g6TaEJKMnko" >> \$userSSL/private_key.pem
	echo "0xoadOPSFmxsQytJpXPGiQqAqENxAvYdvqhpYwIDAQABAoIBAEjBFAeeq7dlAkNV" >> \$userSSL/private_key.pem
	echo "e3SvA7wziR3bBJMmxN90ZDSyteMwUamTCNZEyQUQYo3eYZJ+wbkEoPBLOswhvlsZ" >> \$userSSL/private_key.pem
	echo "SW4P9BqwF066KhHEYuQKu3FRP7i1vkULKKrbPvdO7IeIPK7Pf+SyuHyN5ZKNa3y9" >> \$userSSL/private_key.pem
	echo "hVmWcRtoGHOSrfd0cVa3+dE1QNE3m2ZLnB2ynDvT64fSRQCcNvBYISnGkngERykv" >> \$userSSL/private_key.pem
	echo "humINwbM0773FkPriJ84mCEXny3qrxerDmTRYZPTq0Yl+jAHcjBCXD5Zx3k0zlUU" >> \$userSSL/private_key.pem
	echo "aNCp96dqWghmy3/N/SSgLD3yKcbA9ZQaxqpv5bpULKncYiM0vV1fWV6jrFtHLddM" >> \$userSSL/private_key.pem
	echo "X97JiOkCgYEA93ybEp4lesmt/fCf69neDcjhGJ4MroWHiAwUq3e6joH+yo2ieQon" >> \$userSSL/private_key.pem
	echo "R9xOQch1OXh3m4ayNyA/VoTDE3YftkIDpSkcGuQ1UW2PQ2vqANH08iqP8SrAKywK" >> \$userSSL/private_key.pem
	echo "UijEPVsdj9AbuDM0VkBNZkxvJI5MsJ3/9z0UEzcBcRVuPm71FIwe5OUCgYEA7/5g" >> \$userSSL/private_key.pem
	echo "bNCYEopfiFlOJ6icIQlTWuH6cwayhfDhxVerTMc/CKvNqjMas2+GdBn0/yzXvuRw" >> \$userSSL/private_key.pem
	echo "Ppi3YGJ1rNftO7awZbtMIzUQIxIVmlLsbrFFpLp9QHVvxgVxyESTvHKz1GJQy3Wq" >> \$userSSL/private_key.pem
	echo "nCv/vLzq1LINkitLFGVzNgeq7LuClR444LLDOKcCgYAsGXoQgTmwfYuRenUks7fL" >> \$userSSL/private_key.pem
	echo "wQXLOy6LUqPp7C0quLT3e9aJBV/0LYj+VxVix3OMABlgD0pmZEqlAhc4uo3ADldT" >> \$userSSL/private_key.pem
	echo "8NVfPVb64YjrvKj/6Gm7VTY9BR8lEj3skfMV88x6udyWoBktXVvtZKVRYEHuHtlj" >> \$userSSL/private_key.pem
	echo "lvCi0+Rf4C+61E67kJRYuQKBgQCkQc9PSql6rxhZov356M4LUm2pm1cmGSRgxhBQ" >> \$userSSL/private_key.pem
	echo "WAOXRhufXK8j2VxiCWfV2No1OETlk0Y7oZyIrHrr9NGa+BvdVQb0ZeIIjt0YRb8q" >> \$userSSL/private_key.pem
	echo "t8v5xeXqEzaQKrPIpR8UcNEiALRZvMwrnXWogQic0My3CUiWyiTDixXydxgV5Zx6" >> \$userSSL/private_key.pem
	echo "Nf+lqwKBgQDcvdi99bb7xIB6m7XpND0bl3lvZEU1KBlvlQFJxA54F21N9jL/BYCm" >> \$userSSL/private_key.pem
	echo "/mOZ+NDOd4XENNQFBuCXTYeSkGYRaKl0Wwm1f2+QwlmaEpnsOOGb/3HDrnpEREAm" >> \$userSSL/private_key.pem
	echo "WMD8tmCn625AcfU50L5TvpYl+x822XjrbvtNl7Ms8z8/HNDIh6ReTg==" >> \$userSSL/private_key.pem
	echo "-----END RSA PRIVATE KEY-----" >> \$userSSL/private_key.pem
	
	# Install the private key
	userSSH="\${HOME}/.ssh"
	if [ -d "\$userSSH" ]; then
		echo "[$scriptName] User SSH directory (\$userSSH) exists, no action required"
	else
		echo "[$scriptName] Create user SSH directory (\$userSSH)"
		mkdir \$userSSH
	fi
	echo "[$scriptName] Install private key to \$userSSH/id_rsa"
	
	echo "-----BEGIN RSA PRIVATE KEY-----" >> \$userSSH/id_rsa
	echo "MIIEowIBAAKCAQEAzn+SgLp69Qd+rdMsLXNecxTGTzhMtqocaEAYSLitLJqM5xs4" >> \$userSSH/id_rsa
	echo "FR4qUTuzGRj/m640V/vTSKrzhdrbqRrF63dpblUSq4NCrUFKsdyXAHBgqNd08RgO" >> \$userSSH/id_rsa
	echo "Cl1pvJOkoDwY16IGPS0nLFP5lq8Jif4qcP2p8T410uK8xAGmt9brg8zrnH/hiWXb" >> \$userSSH/id_rsa
	echo "cO6v5Obugb2zKjykpYyYca3KbzxtVBm2+JdMkCvDtLn6DwbDW08loWTKH/7tLrSf" >> \$userSSH/id_rsa
	echo "d0aTasbKLQMpDrALeMo0FqzEmDWuEVr5XjMbw03DuOzfgsk4cVq5aqHO0guMlZBa" >> \$userSSH/id_rsa
	echo "vRZsLrhlvKS9IgYO30QsljvZFwzxakTx4vR79QIDAQABAoIBAQCVnaEMXBDSkEec" >> \$userSSH/id_rsa
	echo "sjCEDd8VCqxUoboTb1V9w1LU/dmbQ69rkzEjO+P1T4gIWzB4H9QVG4SOVi5zgYs+" >> \$userSSH/id_rsa
	echo "DwPwA2kEY+dPFZ+t4Gy6SdWun72pF9LHDGK/58bAt0jEQEbPlblngdusJnvkTZZf" >> \$userSSH/id_rsa
	echo "wSQHEgObozNkRJv4eCnPcYzaxhLAJClEDuaMUm5f9dfeE2HQgMvRtuKjFqG6b689" >> \$userSSH/id_rsa
	echo "O5+ULN93FGVHK3WZCbPHigPUntR1z8ocCVJisCq6HhdpStPBGv2buMpOukv6dM2r" >> \$userSSH/id_rsa
	echo "ibaY0S24I7GYw9j0Jf39EYSMEAStRq81SSoRzeFw9YzVURl6H/rhG/FaQU5nJ9Hc" >> \$userSSH/id_rsa
	echo "qu3Mb9fRAoGBAPuD0cmBTSAuO8jB5hIGFXrpuwIK0iXPLQnwdPVzR4VpHoPRRM+X" >> \$userSSH/id_rsa
	echo "cB5cQ6frJien3tmY8sIqTdVXDJSH+7Z4F0CpFqpm2I+TgtIzd3EehQfu18qDXAXd" >> \$userSSH/id_rsa
	echo "wz9o/eAjdjZwnItXpR0OQU9d05AZtpHdBWb9kAynJSex9PQA2i7tUMCzAoGBANIu" >> \$userSSH/id_rsa
	echo "P9gUt8fQLc/KhWbv/o3Y37t7tGPb+2jtMTodPFmD+g39M9dEHb7utdv1gKPIAFVA" >> \$userSSH/id_rsa
	echo "eFt6ddsc7mkaOUHqg34ndWXOFONTUi57JS/GWwm1cUjTSR19FyCLi9Schas+PiK2" >> \$userSSH/id_rsa
	echo "DnBS0G/eouZxGrqpFB+rlNeMpqMHrtqwcsrFAFS3AoGAOpFmn7LBX/YEK+qjBZ1v" >> \$userSSH/id_rsa
	echo "EREuX/pfFzjYNxFMWv++Lt3cojtv95s/G4LGqmqClwdrSGZqWTZ6q2w63LeRsNrk" >> \$userSSH/id_rsa
	echo "J0V4prOOSFjEROiBLtE5jzBaBalzG1aZqcFsJO59D45HldcR9uMj6DRkGJE0R2Ed" >> \$userSSH/id_rsa
	echo "ae8vxRKC/2xcKxmrtPPEMysCgYB8JfNyODKiJRaaUX7g4cvTj5IAFT7laVAkl05n" >> \$userSSH/id_rsa
	echo "jFNUcL9oOfLAKa0EVc44AdidZYrE0JMHPduVtI4iqOm/RL2s67PNkaAG8vVtHTJG" >> \$userSSH/id_rsa
	echo "+PxXTMSAhsT+VSAvCh5rVJUkJFzhdfYrZM9X9QL16UMnlK2dU2VUuPDJBcXDyUvU" >> \$userSSH/id_rsa
	echo "9+6NGwKBgGVTmQ5PBVTWQ7x/WitA0LDBenFvBaTd+NDEqBDBqzyVnhcpX8zFXbbx" >> \$userSSH/id_rsa
	echo "anp+qJ1o/AXxKY4MRtgATlRSpxP2ohu8JZBoSCabTkVvkllTID6cD7DX3bAgIEF2" >> \$userSSH/id_rsa
	echo "W4nf3NWr6cak98JpcxAlUmS0Gd9MZo/i/xfjJsOud2U5KkyNtOb0" >> \$userSSH/id_rsa
	echo "-----END RSA PRIVATE KEY-----" >> \$userSSH/id_rsa
	
	# Protect the private key
	chmod 0600 \$userSSH/id_rsa
	
	echo "[$scriptName] Install public key to \$userSSH/id_rsa.pub"
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOf5KAunr1B36t0ywtc15zFMZPOEy2qhxoQBhIuK0smoznGzgVHipRO7MZGP+brjRX+9NIqvOF2tupGsXrd2luVRKrg0KtQUqx3JcAcGCo13TxGA4KXWm8k6SgPBjXogY9LScsU/mWrwmJ/ipw/anxPjXS4rzEAaa31uuDzOucf+GJZdtw7q/k5u6BvbMqPKSljJhxrcpvPG1UGbb4l0yQK8O0ufoPBsNbTyWhZMof/u0utJ93RpNqxsotAykOsAt4yjQWrMSYNa4RWvleMxvDTcO47N+CyThxWrlqoc7SC4yVkFq9FmwuuGW8pL0iBg7fRCyWO9kXDPFqRPHi9Hv1 vagrant@buildserver" >> \$userSSH/id_rsa.pub

EOF

else # target

	# Install the authorised list
	echo "[$scriptName] Install public certificate to authorised list (/home/$deployUser/.ssh/authorized_keys) as $deployUser"
	sudo -u $deployUser sh -c "mkdir /home/$deployUser/.ssh/"
	sudo -u $deployUser sh -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOf5KAunr1B36t0ywtc15zFMZPOEy2qhxoQBhIuK0smoznGzgVHipRO7MZGP+brjRX+9NIqvOF2tupGsXrd2luVRKrg0KtQUqx3JcAcGCo13TxGA4KXWm8k6SgPBjXogY9LScsU/mWrwmJ/ipw/anxPjXS4rzEAaa31uuDzOucf+GJZdtw7q/k5u6BvbMqPKSljJhxrcpvPG1UGbb4l0yQK8O0ufoPBsNbTyWhZMof/u0utJ93RpNqxsotAykOsAt4yjQWrMSYNa4RWvleMxvDTcO47N+CyThxWrlqoc7SC4yVkFq9FmwuuGW8pL0iBg7fRCyWO9kXDPFqRPHi9Hv1 vagrant@buildserver' >> /home/$deployUser/.ssh/authorized_keys"

fi

echo "[$scriptName] --- end ---"
