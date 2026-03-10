# VASP Lab Automation Scripts

This repository contains a suite of Bash scripts designed to automate routine VASP tasks, including job execution, energy extraction, and the setup of post-processing calculations like Density of States (DOS) and LOBSTER analyses. 

These tools are designed to work recursively, meaning you can run them from a master project folder and they will automatically scan and process all subdirectories containing completed VASP jobs.

---

## 🛠️ Initial Setup

To make these commands globally accessible from anywhere in your terminal, follow these steps:

1. **Get the scripts:**
   You can either clone this repository directly or set up the folder manually. Ensure the folder is named `lab_shortcuts` and is placed in your home directory.

   **Option A: Clone via Git (Recommended)**
   ```bash
   git clone https://github.com/1n-finity/lab_shortcuts.git ~/lab_shortcuts
   ```

   **Option B: Manual Setup**
   ```bash
   mkdir -p ~/lab_shortcuts
   # Move the downloaded .sh files into this folder
   ```

2. **Run the setup script:**
   Navigate to the folder and execute the `labsetup.sh` script. This will make all scripts executable and bind them to short commands (aliases) in your `.bashrc` file.
   ```bash
   cd ~/lab_shortcuts
   chmod u+x labsetup.sh
   ./labsetup.sh
   ```

3. **Activate the shortcuts:**
   Reload your bash configuration to apply the new aliases immediately.
   ```bash
   source ~/.bashrc
   ```

---

## 🚀 Command Reference & Usage

Once set up, you can use the following commands from any directory in your terminal. 

### 1. `runvasp`
* **What it does:** A lightweight execution wrapper for VASP. It loads the required NVIDIA HPC modules (`nvhpc-hpcx-cuda13/25.11`) and initiates the standard VASP binary using `mpirun`.
* **How to use:** Navigate to the directory containing your `INCAR`, `POSCAR`, `POTCAR`, and `KPOINTS` files, and simply type:
  ```bash
  runvasp
  ```

### 2. `vaspeng`
* **What it does:** Recursively scans the current directory and all subdirectories for VASP optimizations. It checks the `OUTCAR` to verify if the job reached the required accuracy. If successful, it extracts the final converged `energy(sigma->0)` value.
* **Output:** Generates an `energies.csv` file in the directory where the command was run, containing two columns: the folder path and the extracted energy in eV.
* **How to use:** Run it from your master project folder to tabulate energies across multiple structures.
  ```bash
  vaspeng
  ```

### 3. `makedos`
* **What it does:** Automates the transition from a standard optimization to a DOS calculation. It recursively searches for completed `OUTCAR` files. For each successful run, it:
  * Creates a new `DOS` subfolder.
  * Copies `CONTCAR` (renamed to `POSCAR`), `POTCAR`, and `KPOINTS` into the `DOS` folder.
  * Generates a pre-configured `INCAR` specifically tuned for DOS (e.g., `ICHARG = 2`, `LORBIT = 11`, `LCHARG = .TRUE.`).
  * *Safety feature:* Skips folders that are already named `DOS` or `LOBSTER`.
* **How to use:** Run it from the root folder containing your converged VASP runs.
  ```bash
  makedos
  ```

### 4. `makelobster`
* **What it does:** Prepares directories for LOBSTER calculations. Similar to `makedos`, it recursively searches for successful VASP optimizations. For each one, it:
  * Creates a new `LOBSTER` subfolder.
  * Copies necessary input files (`CONTCAR` to `POSCAR`, etc.).
  * Automatically parses the original `OUTCAR` to find the `NBANDS` value, multiplies it by 2, and dynamically injects this new value into a LOBSTER-ready `INCAR` file (which includes critical settings like `ISYM = -1`).
  * *Safety feature:* Skips folders already named `DOS` or `LOBSTER`.
* **How to use:** Run it from the root folder containing your converged VASP runs.
  ```bash
  makelobster
  ```

### 5. `nvuse`
* **What it does:** Provides a clear, at-a-glance summary of GPU resource usage. It first displays the total and available memory across all detected GPUs. Below that, it lists the active compute processes, showing the PID, user, memory consumed, and the command being run.
* **How to use:** Run it anytime to check if the node has enough free resources before submitting a new job.
  ```bash
  nvuse
  ```

---

**Note:** If you add new scripts to the `~/lab_shortcuts` folder in the future, simply re-run `./labsetup.sh` and `source ~/.bashrc` to register the new commands.
