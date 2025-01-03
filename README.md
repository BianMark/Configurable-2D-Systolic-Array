# CNNs on Multi-Core 2D Systolic Array with Pruning and Huffman Coding
This is the repository for the Final Project of ECE284 (UCSD FA24), which reliaizes a 8*8 Configurable 2D Systolic Array with Hardware Pruning and Huffman Coding.

## Input data format
For **Output Stationary** mode, the input data format:

***weight_os_3ic.txt***:

    k0_oc7_ic0  k0_oc6_ic0  ...  k0_oc0_ic0
    k1_oc7_ic0  ...              k1_oc0_ic0
    ...
    k8_oc7_ic0  ...              k8_oc0_ic0

    k0_oc7_ic1  k0_oc6_ic1  ...  k0_oc0_ic1
    k1_oc7_ic1  ...              k1_oc0_ic1
    ...
    k8_oc7_ic1  ...              k8_oc7_ic1

    k0_oc7_ic2  k0_oc6_ic2  ...  k0_oc0_ic2
    k1_oc7_ic2  ...              k1_oc0_ic2
    ...
    k8_oc7_ic2  ...              k8_oc7_ic2


***activation_os_3ic_tile0.txt***:

    n9  n8  n7  n6  n3  n2  n1  n0
    n10 ...                     n1
    n11 ...                     n2

    n15 ...                     n6
    n16 ...                     n7
    n17 ...                     n8

    n21 ...                     n12
    n22 ...                     n13
    n23 n22 n21 n20 n17 n16 n15 n14

***activation_os_3ic_tile1.txt***:

    n21 n20 n19 n18 n15 n14 n13 n12
    n22 ...                     n13
    n23 ...                     n14

    n27 ...                     n18
    n28 ...                     n19
    n29 ...                     n20

    n33 ...                     n24
    n34 ...                     n25
    n35 n34 n33 n32 n29 n28 n27 n26
