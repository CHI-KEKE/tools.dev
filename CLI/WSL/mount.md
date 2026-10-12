

## /mnt/c 是什麼？


WSL 會把 Windows 磁碟掛載進 Linux


Windows                 WSL
────────────────────────────────────
C:\                     /mnt/c/
C:\Users                 /mnt/c/Users/
C:\Users\Allen           /mnt/c/Users/Allen/
C:\Users\Allen\Desktop   /mnt/c/Users/Allen/Desktop/


所以：
cd /mnt/c/Users/Allen

其實就是在操作 Windows 的：
C:\Users\Allen


Windows filesystem
C:\
└── Users
    └── Allen
         ↑
         │ WSL 看到它
         │
         └── /mnt/c/Users/Allen


WSL Linux filesystem
/
├── etc
├── usr
├── var
└── home
    └── yoyo
         ↑
         └── ~


## 「每次進 WSL 都直接回 Linux 的家」


wsl ~


