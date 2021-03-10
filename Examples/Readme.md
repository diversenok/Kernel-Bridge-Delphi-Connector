# Example Projects

## ParentTokenId

The project demonstrates retrieving the content of the `ParentTokenId` field from the `TOKEN` kernel structure. We first need to determine its offset since it can change depending on the version of Windows. We craft a token with a known parent, retrieve the first 256 bytes of the object's body from the kernel memory, and scan it, searching for the known unique pattern. After that, we can read the value from other objects using the same offset. The program also demonstrates opening primary/impersonation tokens and copying handles from other processes.

Used functions from Kernel Bridge:
 - `KbOpenProcess` — via `KbxOpenProcess`
 - `KbOpenThread` — via `KbxOpenThread`
 - `KbCopyMoveMemory` — via `KbxMemory.Read<T>`
 - `KbLoadAsDriver` — via `KbxLoadAsDriver`
 - `KbUnload` — used internally by `IAutoReleaseable`
 - `KbCloseHandle` — used internally by `IAutoReleaseable`
