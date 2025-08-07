# simulink-model-cloner
Simulink Model Cloner :

A MATLAB utility script that clones a Simulink model — including blocks, their positions, and signal connections — from one model to another.
I wanted to generate Simulink blocks automatically using a script. I started by trying first to clone an existing IEEE model for load flow analysis, then I can just improve to generate random cases, well it's under refinement, particularly for line connection .


--- 
What This Script Does :

This tool automates the process of duplicating a Simulink model programmatically using MATLAB code. I am presenting 2

clone_model_safe: that clowns block by block 
full_model_copy: create a subsystem and brute copy it to another model 


--- 
Features:
- Clones all **top-level blocks** from the source model to a new model
- Preserves **positions**, **names**, and **block types**
- Reconnects signal **lines using port handles** instead of relying on names (which may be unreliable)

---
What We Tried to Achieve :

The ultimate goal was to **clone an IEEE 9-bus system model**, fully preserving:
- All power system components (generators, buses, transformers, loads, references, etc.)
- Connections (wires/lines)
- Layout


What Worked :

- All **blocks were successfully cloned** with correct positioning and naming
- Block handles and port numbers were mapped and used properly
- Final model file saved and auto-closed after cloning

---

What Didn't Work :

Despite using port handles and full name remapping, **many lines failed to reconnect** due to:

- Multiline block names (e.g., `"Bus1\n16.5kV"` or `"G2C//PV\n163MW\n1.025pu"`) are being interpreted incorrectly
- Labels including newline characters (`\n`) that broke valid Simulink object names
- Some ports have inconsistent or inaccessible handles during cloning
- Potential differences between *displayed block name* and internal *block handle name*

---

Known Limitations

- **Line connections are unreliable** if the block names contain newlines or special formatting
- **Nested subsystems**, **libraries**, and **masked blocks** are not handled
- **Line annotations** and **labels** are not preserved
- Does not support cloning of **state machines**, **bus objects**, or **complex signals**

---

How to Use

```matlab
clone_model_safe ('IEEE9Bus_Original', 'IEEE9Bus_Cloned')
full_model_copy ('IEEE9Bus_Original', 'IEEE9Bus_Cloned')
```
you can do it for any model you want, not just an IEEEBus system. Make sure the source model, like in my case (`IEEE9Bus_Original.slx`), is on your MATLAB path and not already open.

---



Future Improvements

We invite contributions to fix or improve:
- Line connection logic (robust handling of multi-line labels)
- Support for nested systems
- Optionally rename block names to flat, valid strings
- Visual comparison of source vs. cloned model
- Export log of what was cloned/failed

---

Author & Notes

This project was developed by Youssef El Khaldouni during a research workflow that required model duplication for advanced simulation and optimization of power systems

Feel free to work, improve, or submit issues if you're using this in your simulation workflow.

---
