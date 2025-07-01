#!/bin/bash

echo "=== System Dependencies Check ==="
echo "This script checks for system dependencies required by install_vllm_sglang_mcore.sh"
echo

# Check CUDA installation and version
echo "1. CUDA Check:"
if command -v nvcc &> /dev/null; then
    echo "✓ CUDA compiler (nvcc) found:"
    nvcc --version | grep "release"
    echo "  CUDA runtime version:"
    nvidia-smi --query-gpu=driver_version,cuda_version --format=csv,noheader,nounits | head -1
else
    echo "✗ CUDA compiler (nvcc) not found"
fi

# Check NVIDIA driver
echo
echo "2. NVIDIA Driver Check:"
if command -v nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA driver found:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo "✗ NVIDIA driver (nvidia-smi) not found"
fi

# Check Python version
echo
echo "3. Python Check:"
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    echo "✓ Python found: $python_version"
    if python3 -c "import sys; assert sys.version_info >= (3, 8)" 2>/dev/null; then
        echo "  ✓ Python version >= 3.8 (required for packages)"
    else
        echo "  ✗ Python version < 3.8 (may cause issues)"
    fi
else
    echo "✗ Python3 not found"
fi

# Check pip
echo
echo "4. Package Manager Check:"
if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
    echo "✓ pip found"
    pip --version 2>/dev/null || pip3 --version
else
    echo "✗ pip not found"
fi

# Check git (required for Megatron/TransformerEngine installation)
echo
echo "5. Git Check:"
if command -v git &> /dev/null; then
    echo "✓ Git found: $(git --version)"
else
    echo "✗ Git not found (required for TransformerEngine and Megatron installation)"
fi

# Check wget (required for downloading wheels)
echo
echo "6. Download Tools Check:"
if command -v wget &> /dev/null; then
    echo "✓ wget found: $(wget --version | head -1)"
else
    echo "✗ wget not found (required for downloading flash-attention and flashinfer wheels)"
fi

# Check system architecture
echo
echo "7. System Architecture Check:"
arch=$(uname -m)
echo "  Architecture: $arch"
if [ "$arch" = "x86_64" ]; then
    echo "  ✓ x86_64 architecture (compatible with pre-built wheels)"
else
    echo "  ⚠ Non-x86_64 architecture (pre-built wheels may not work)"
fi

# Check Linux distribution
echo
echo "8. Operating System Check:"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  OS: $NAME $VERSION"
    echo "  ✓ Linux distribution detected"
else
    echo "  ⚠ Cannot detect Linux distribution"
fi

# Check GCC compiler (required for building some packages)
echo
echo "9. Build Tools Check:"
if command -v gcc &> /dev/null; then
    echo "✓ GCC compiler found: $(gcc --version | head -1)"
else
    echo "✗ GCC compiler not found (may be needed for building packages)"
fi

if command -v g++ &> /dev/null; then
    echo "✓ G++ compiler found: $(g++ --version | head -1)"
else
    echo "✗ G++ compiler not found (may be needed for building packages)"
fi

# Check CUDA compatibility
echo
echo "10. CUDA Compatibility Check:"
if command -v nvidia-smi &> /dev/null; then
    cuda_version=$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader,nounits | head -1)
    echo "  CUDA runtime version: $cuda_version"
    
    # Check if CUDA version is compatible with torch 2.6 (requires CUDA 11.8+)
    if python3 -c "
import re
cuda_ver = '$cuda_version'
major, minor = map(int, re.findall(r'(\d+)\.(\d+)', cuda_ver)[0])
if major > 11 or (major == 11 and minor >= 8):
    print('  ✓ CUDA version compatible with PyTorch 2.6 (requires 11.8+)')
else:
    print('  ✗ CUDA version may be incompatible with PyTorch 2.6 (requires 11.8+)')
" 2>/dev/null; then
        :
    else
        echo "  ⚠ Cannot verify CUDA compatibility"
    fi
fi

# Check available disk space
echo
echo "11. Disk Space Check:"
available_space=$(df -h . | awk 'NR==2 {print $4}')
echo "  Available space in current directory: $available_space"
echo "  ⚠ Installation may require several GB of disk space"

# Check memory
echo
echo "12. Memory Check:"
if command -v free &> /dev/null; then
    total_mem=$(free -h | awk 'NR==2{print $2}')
    available_mem=$(free -h | awk 'NR==2{print $7}')
    echo "  Total memory: $total_mem"
    echo "  Available memory: $available_mem"
    echo "  ⚠ Building TransformerEngine may require significant memory"
else
    echo "  ⚠ Cannot check memory usage"
fi

echo
echo "=== Summary ==="
echo "If you see ✗ for critical dependencies (CUDA, Python, pip), please install them first."
echo "If you see ⚠ warnings, the installation may still work but could face issues."
echo "For TransformerEngine compilation, ensure you have sufficient memory and disk space."