#!/usr/bin/env bash

# This software is in the public domain, furnished "as is", without technical
# support, and with no warranty, express or implied, as to its usefulness for
# any purpose.
#
# Author: Pascal Germroth <pascal@ensieve.org>

primes="2 3 5 7 11 13"
max_size=25
ns=`for p in $primes ; do
	for ((x = p ; x <= max_size ; x *= p)) ; do
		echo $x
	done
done | sort -n | paste -s -d' '`

echo "#ifndef VEXCL_FFT_UNROLLED_DFT_HPP"
echo "#define VEXCL_FFT_UNROLLED_DFT_HPP"
echo
echo "// Autogenerated file, do not edit!"
echo "// see https://github.com/neapel/vexcl-genfft"
echo
echo "#include <vector>"
echo "#include <string>"
echo
echo "namespace vex {"
echo "namespace fft {"
echo
echo "static std::vector<size_t> supported_primes() {"
echo "    static const size_t p[] = {`echo "$primes" | sed 's/ /,/g'`};"
echo "    return std::vector<size_t>(p, p + sizeof(p) / sizeof(p[0]));"
echo "}"
echo
echo "static std::vector<size_t> supported_kernel_sizes() {"
echo "    static const size_t s[] = {`echo "$ns" | sed 's/ /,/g'`};"
echo "    return std::vector<size_t>(s, s + sizeof(s) / sizeof(s[0]));"
echo "}"
echo
echo

function code() {
	/usr/bin/time -f "n=$1 in %Us" ./cl_gen_notw.native -n $1 -name "dft$1" -sign $2 -compact -fma -reorder-insns -reorder-loads -reorder-stores -schedule-for-pipeline -pipeline-latency 4 -standalone | gcc -E -P -C - | indent -i 4 -nut | while IFS= read -r line ; do
		echo -ne "\n            \"${line}\\\n\""
	done
}

echo "static std::string in_place_dft(size_t n, bool invert) {"
echo "    switch(n) {"
for n in $ns ; do
	echo -n "        case $n: return invert ?"
	code $n 1
	echo -n " : "
	code $n -1
	echo ";"
	echo
done
echo '        default: throw std::logic_error("Unsupported kernel size.");';
echo "    }"
echo "}"
echo
echo
echo "} // namespace fft"
echo "} // namespace vex"
echo
echo "#endif"
