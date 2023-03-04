# Skripsi Aghniya Abdurrahman Mannan - 140810190025
Judul : Implementasi Runtime Security Pada Kubernetes

Rincian :

Saya akan membuat kluster kubernetes pada google cloud platform (GCP) dengan memanfaatkan salah satu service mereka yaitu Google Kubernetes Engine (GKE). Kemudian saya akan melakukan serangan privilege escalation dengan cara mencoba terhubung ke shell dari kluster kubernetes tersebut, kemudian mendapatkan privilege untuk membuat pod yang kemudian akan dimanfaatkan untuk membuat pod baru yaitu pod cryptominer. Setelah serangan tersebut, saya akan melihat efek yang ditimbulkan dari serangan tersebut. Setelah itu, saya akan melakukan remediasi dari serangan yang telah dilakukan.

Setelah semua hal tadi dilakukan, saya akan mendeploy service runtime security tools yang kemudian akan diuji terhadap serangan yang sama. Kemudian, saya akan mengamati apakah tools yang sudah dideploy dan dikonfigurasi mampu mendeteksi dan meremediasi serangan yang telah dilakukan dan berapa lama waktu yang dibutuhkan untuk melakukan deteksi dan juga remediasinya.

Repositori kode ini dibuat untuk menampung skrip konfigurasi kubernetes pada folder cloud-shell-setup dan skrip untuk penyerangan pada folder attacking-scripts.