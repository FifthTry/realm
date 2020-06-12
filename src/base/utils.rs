pub fn elapsed(e: std::time::Instant) -> String {
    let e = e.elapsed();
    let nanos = e.subsec_nanos();
    let fraction = match nanos {
        t if nanos < 1000 => format!("{}ns", t),
        t if nanos < 1_000_000 => format!("{:.*}µs", 3, f64::from(t) / 1000.0),
        t => format!("{:.*}ms", 3, f64::from(t) / 1_000_000.0),
    };
    let secs = e.as_secs();
    match secs {
        _ if secs == 0 => fraction,
        t if secs < 5 => format!("{}.{:06}s", t, nanos / 1000),
        t if secs < 60 => format!("{}.{:03}s", t, nanos / 1_000_000),
        t if secs < 3600 => format!("{}m {}s", t / 60, t % 60),
        t if secs < 86400 => format!("{}h {}m", t / 3600, (t % 3600) / 60),
        t => format!("{}s", t),
    }
}
