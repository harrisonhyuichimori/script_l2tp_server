#!/bin/bash

echo "Escolha uma opção:"
echo "1) Instalar Servidor L2TP/IPsec"
echo "2) Instalar Cliente L2TP/IPsec"
echo "3) Adicionar Novo Cliente no Servidor"
read -p "Opção: " opcao

if [ "$opcao" == "1" ]; then
    # Instalação do servidor
    sudo apt-get update && sudo apt-get upgrade -y
    wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh
    echo "Servidor VPN L2TP/IPsec instalado com sucesso."

elif [ "$opcao" == "2" ]; then
    # Instalação do cliente
    read -p "Digite o endereço do servidor VPN: " servidor
    read -p "Digite o nome do cliente: " cliente
    read -sp "Digite a senha do cliente: " senha
    echo ""

    # Instalando pacotes necessários
    sudo apt-get update
    sudo apt-get install xl2tpd strongswan ppp -y

    # Verificando se os diretórios e arquivos necessários existem
    if [ ! -d "/etc/xl2tpd" ]; then
      sudo mkdir /etc/xl2tpd
    fi

    # Configuração do IPsec
    sudo bash -c "cat > /etc/ipsec.conf <<EOF
config setup
  charondebug="ike 2, knl 2, cfg 2"

conn L2TP-PSK
  keyexchange=ikev1
  authby=secret
  type=transport
  left=%defaultroute
  leftprotoport=17/1701
  right=$servidor
  rightprotoport=17/1701
  auto=start
EOF"

    sudo bash -c "echo ': PSK \"chave_presente_no_servidor\"' > /etc/ipsec.secrets"

    # Configuração do L2TP
    sudo bash -c "cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac vpn-connection]
lns = $servidor
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF"

    # Configuração do PPP
    sudo bash -c "cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
usepeerdns
connect-delay 5000
name $cliente
password $senha
EOF"

    # Reiniciando serviços
    sudo ipsec restart
    sudo service xl2tpd restart || echo "O serviço xl2tpd não foi encontrado ou não está instalado corretamente."
    echo "Cliente VPN L2TP/IPsec instalado com sucesso."

elif [ "$opcao" == "3" ]; then
    # Adicionar novo cliente no servidor
    read -p "Digite o nome do cliente: " cliente
    read -sp "Digite a senha do cliente: " senha
    echo ""

    sudo bash -c "echo '$cliente l2tpd $senha *' >> /etc/ppp/chap-secrets"
    sudo systemctl restart ipsec xl2tpd
    echo "Novo cliente adicionado com sucesso."
else
    echo "Opção inválida."
fi
