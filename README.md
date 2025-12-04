# HubbOS - Sistema Operacional Customizado

## Descrição

HubbOS é um sistema operacional mínimo compilado do zero com:
- **Linux Kernel 6.6.1** (versão estável)
- **Bash 5.2.21** (shell interativo)
- Bibliotecas essenciais do sistema

## Características

- **Tamanho**: ~480 MB (ISO)
- **Boot**: GRUB com suporte a multiboot
- **Sistema de Arquivos**: RAM-based com initramfs CPIO
- **Shell**: Bash 5.2.21 compilado estaticamente

## Estrutura do Projeto

```
/workspaces/Hubb/
├── build/                 # Diretório de compilação
│   ├── bash-5.2.21/      # Código-fonte do Bash
│   ├── linux-6.6.1/      # Código-fonte do Kernel
├── sources/              # Arquivos baixados (tar.gz)
│   ├── bash-5.2.21.tar.gz
│   ├── linux-6.6.1.tar.gz
├── rootfs/               # Sistema de arquivos raiz
├── iso/                  # Estrutura da ISO
├── build_iso.sh          # Script de build
├── HubbOS.iso            # Imagem ISO pronta para inicialização
└── README.md             # Este arquivo
```

## Como Usar a ISO

### Com QEMU:
```bash
qemu-system-x86_64 -cdrom HubbOS.iso -m 1024 -boot d
```

### Com VirtualBox:
1. Crie uma nova máquina virtual (Linux, 64-bit)
2. Configure o CD-ROM para usar `HubbOS.iso`
3. Inicie a máquina

### Com físico (USB):
```bash
sudo dd if=HubbOS.iso of=/dev/sdX bs=4M
```

## Compilação Detalhada

A compilação foi realizada em 6 etapas:

1. **Download de Dependências**
	- Linux Kernel 6.6.1 (215 MB)
	- Bash 5.2.21 (11 MB)

2. **Compilação do Kernel**
	- Configuração padrão para x86_64
	- Tempo: ~11 minutos

3. **Compilação do Bash**
	- Sem malloc customizado
	- Tempo: ~1 minuto

4. **Preparação do Rootfs**
	- Cópia de kernel, bash e bibliotecas
	- Script init customizado

5. **Criação de Initramfs**
	- Formato CPIO (newc)
	- Tamanho: ~467 MB

6. **Geração da ISO**
	- Boot com GRUB
	- Multiboot support
	- Tamanho final: ~480 MB

## Especificações do Build

- **Host OS**: Ubuntu 24.04.3 LTS
- **Arquitetura**: x86_64
- **Compressor**: xz (kernel)
- **Bootloader**: GRUB 2.12

## Arquivos Gerados

- `HubbOS.iso` - Imagem ISO bootável
- `rootfs.cpio` - Imagem do sistema de arquivos

## Notas

- O sistema inicia com um prompt bash interativo
- Todos os binários compilados no local
- Sem dependências de distribuição Linux
- Totalmente customizável para futuras extensões
# Hubb