# Kernel-Bridge Delphi Connector

This project is a library for using the user-mode side of the API provided by [Kernel Bridge](https://github.com/HoShiMin/Kernel-Bridge) with Delphi. It allows manipulating processes and threads from kernel-mode, contains functions for directly manipulating kernel and physical memory, and more.

## Content

The library includes a single header file — **KernelBridgeApi.pas** — a translated version of definitions for the functions exported by **User-Bridge.dll**. Although this file depends on the headers from NtUtils, it should be simple to inline and remove those dependencies if necessary.

The rest files are the wrappers that allow better integration of the functionality into the language and automated resource lifetime management. These modules are an extension of my [NtUtils library](https://github.com/diversenok/NtUtilsLibrary).

File                                  | Description
------------------------------------- | ------------
**KernelBridge.pas**                  | Loader for the Kernel Bridge Driver, kernel shellcode injection.
**KernelBridge.Processes.pas**        | Process manipulation
**KernelBridge.Processes.Memory.pas** | Reading, writing, allocating, and protecting process memory.
**KernelBridge.Threads.pas**          | Thread creation and manipulation, APC queueing.
**KernelBridge.Section.pas**          | Section manipulation.
**KernelBridge.Memory.pas**           | Operations with virtual and physical memory.
**KernelBridge.Memory.Mdl.pas**       | Operations with Memory Descriptor Lists.

The functions in these modules are similar to those of the API in the corresponding categories. The main difference is that operations that require a cleanup return instances of IAutoReleasable (or its descendants). This interface ensures that the underlying resources get automatically released when the last reference goes out of scope.

## Examples

See the [examples](Examples) folder for more details.
