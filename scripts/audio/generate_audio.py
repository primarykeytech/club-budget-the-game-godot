import math
import struct
import wave
import os

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1) # mono
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        raw_data = bytearray()
        for s in samples:
            val = int(max(-1.0, min(1.0, s)) * 32767)
            raw_data.extend(struct.pack('<h', val))
        wav_file.writeframes(raw_data)

def gen_sine(freq, duration, decay=0.0):
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-decay * t) if decay > 0 else 1.0
        val = math.sin(2 * math.pi * freq * t) * env
        samples.append(val)
    return samples

def gen_select():
    samples = []
    duration = 0.06
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-55 * t)
        val = 0.7 * math.sin(2 * math.pi * 1200 * t) + 0.3 * math.sin(2 * math.pi * 2400 * t)
        samples.append(val * env * 0.7)
    return samples

def gen_confirm():
    t1 = gen_sine(587.33, 0.08, 25)
    t2 = gen_sine(880.00, 0.12, 18)
    return [0.6 * s for s in (t1 + t2)]

def gen_cash():
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env1 = math.exp(-12 * t)
        env2 = math.exp(-18 * t)
        val = (
            0.5 * math.sin(2 * math.pi * 987.77 * t) * env1 +
            0.35 * math.sin(2 * math.pi * 1975.53 * t) * env1 +
            0.25 * math.sin(2 * math.pi * 2637.02 * t) * env2
        )
        samples.append(val * 0.7)
    return samples

def gen_alarm():
    duration = 0.3
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 380 - (150 * (t / duration))
        env = math.exp(-6 * t)
        val = 0.5 * math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
        samples.append(val * env * 0.8)
    return samples

def gen_correct():
    c5 = gen_sine(523.25, 0.07, 15)
    e5 = gen_sine(659.25, 0.07, 15)
    g5 = gen_sine(783.99, 0.07, 15)
    c6 = gen_sine(1046.50, 0.28, 8)
    return [0.65 * s for s in (c5 + e5 + g5 + c6)]

def gen_game_over():
    c5 = gen_sine(523.25, 0.2, 8)
    b4 = gen_sine(493.88, 0.2, 8)
    a4 = gen_sine(440.00, 0.2, 8)
    ab4 = gen_sine(415.30, 0.25, 8)
    g4 = gen_sine(392.00, 0.45, 5)
    return [0.7 * s for s in (c5 + b4 + a4 + ab4 + g4)]

def gen_victory():
    c5 = gen_sine(523.25, 0.12, 10)
    e5 = gen_sine(659.25, 0.12, 10)
    g5 = gen_sine(783.99, 0.14, 10)
    g5_2 = gen_sine(783.99, 0.10, 10)
    c6 = gen_sine(1046.50, 0.50, 4)
    return [0.75 * s for s in (c5 + e5 + g5 + g5_2 + c6)]

def gen_bg_music():
    # 16-bar looping theme at 116 BPM (~33.1 seconds)
    bpm = 116.0
    beat_dur = 60.0 / bpm
    total_beats = 64 # 16 bars * 4 beats
    total_duration = total_beats * beat_dur
    num_samples = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * num_samples

    # Helper note frequencies (Hz)
    C3, D3, E3, F3, G3, A3, B3 = 130.81, 146.83, 164.81, 174.61, 196.00, 220.00, 246.94
    C4, D4, E4, F4, G4, A4, B4 = 261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88
    C5, D5, E5, F5, G5, A5, B5 = 523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77
    C6, D6, E6 = 1046.50, 1174.66, 1318.51

    # 1. Bass line: Bouncy bass pattern (Root on beat 0, Fifth/Octave on beat 2.5 and 3)
    # 16 bars of chords:
    # Bar 1: C  | Bar 2: G/B | Bar 3: Am | Bar 4: F
    # Bar 5: C  | Bar 6: Em  | Bar 7: F  | Bar 8: G
    # Bar 9: Am | Bar 10: Em | Bar 11: F | Bar 12: C
    # Bar 13: Dm| Bar 14: G  | Bar 15: C | Bar 16: G
    bar_chords = [
        (C3, G3), (B3/2, G3), (A3/2, E3), (F3/2, C3),
        (C3, G3), (E3/2, B3/2), (F3/2, C3), (G3/2, D3),
        (A3/2, E3), (E3/2, B3/2), (F3/2, C3), (C3, G3),
        (D3, A3/2), (G3/2, D3), (C3, G3), (G3/2, D3)
    ]

    for bar_idx, (root, fifth) in enumerate(bar_chords):
        bar_start = bar_idx * 4 * beat_dur
        # Note on beat 0 (length 1.5 beat)
        # Note on beat 2 (fifth, length 1.0 beat)
        # Note on beat 3 (root, length 0.8 beat)
        b_events = [
            (root, bar_start + 0.0 * beat_dur, 1.2),
            (fifth, bar_start + 2.0 * beat_dur, 0.8),
            (root, bar_start + 3.0 * beat_dur, 0.8),
        ]
        for freq, start, length_b in b_events:
            s_idx = int(start * SAMPLE_RATE)
            d_samps = int(length_b * beat_dur * SAMPLE_RATE)
            for i in range(d_samps):
                pos = s_idx + i
                if pos < num_samples:
                    t = i / SAMPLE_RATE
                    env = math.exp(-3.5 * t)
                    # Round warm bass tone
                    val = (0.28 * math.sin(2 * math.pi * freq * t) + 0.12 * math.sin(4 * math.pi * freq * t)) * env
                    samples[pos] += val

    # 2. Main Melody: Catchy, playful math club theme
    melody_notes = [
        # --- Section 1 (Bars 1-4) ---
        (E5, 0.0, 0.8), (G5, 1.0, 0.8), (C6, 2.0, 1.4),
        (B5, 4.0, 0.8), (G5, 5.0, 0.8), (D5, 6.0, 1.4),
        (C5, 8.0, 0.8), (E5, 9.0, 0.8), (A5, 10.0, 1.4),
        (G5, 12.0, 0.8), (F5, 13.0, 0.8), (E5, 14.0, 0.8), (D5, 15.0, 0.8),

        # --- Section 2 (Bars 5-8) ---
        (E5, 16.0, 0.8), (G5, 17.0, 0.8), (C6, 18.0, 1.4),
        (B5, 20.0, 0.8), (G5, 21.0, 0.8), (E5, 22.0, 1.4),
        (F5, 24.0, 0.8), (A5, 25.0, 0.8), (C6, 26.0, 1.0), (D6, 27.0, 0.8),
        (B5, 28.0, 1.8), (G5, 30.0, 1.8),

        # --- Section 3 (Bars 9-12: Math Puzzle syncopation) ---
        (A5, 32.0, 0.5), (C6, 32.5, 0.5), (E6, 33.0, 0.8), (D6, 34.0, 0.8), (C6, 35.0, 0.8),
        (B5, 36.0, 0.5), (G5, 36.5, 0.5), (E5, 37.0, 0.8), (G5, 38.0, 1.4),
        (A5, 40.0, 0.5), (F5, 40.5, 0.5), (D5, 41.0, 0.8), (F5, 42.0, 0.8), (A5, 43.0, 0.8),
        (G5, 44.0, 1.0), (E5, 45.0, 0.8), (C5, 46.0, 1.8),

        # --- Section 4 (Bars 13-16: Loop turnaround) ---
        (F5, 48.0, 0.8), (A5, 49.0, 0.8), (D6, 50.0, 1.4),
        (B5, 52.0, 0.8), (G5, 53.0, 0.8), (F5, 54.0, 1.4),
        (E5, 56.0, 0.8), (G5, 57.0, 0.8), (C6, 58.0, 1.4),
        (D6, 60.0, 0.8), (B5, 61.0, 0.8), (C6, 62.0, 1.8),
    ]

    for freq, beat_start, length_b in melody_notes:
        s_idx = int(beat_start * beat_dur * SAMPLE_RATE)
        d_samps = int(length_b * beat_dur * SAMPLE_RATE)
        for i in range(d_samps):
            pos = s_idx + i
            if pos < num_samples:
                t = i / SAMPLE_RATE
                env = math.exp(-3.0 * t)
                # Vibrant warm synth lead with soft harmonics
                val = (
                    0.24 * math.sin(2 * math.pi * freq * t) +
                    0.10 * math.sin(4 * math.pi * freq * t) +
                    0.04 * math.sin(6 * math.pi * freq * t)
                ) * env
                samples[pos] += val

    # 3. Light arpeggios & chord backing on off-beats
    for bar_idx in range(16):
        bar_start = bar_idx * 4 * beat_dur
        # Add soft eighth-note arpeggio ticks
        root, fifth = bar_chords[bar_idx]
        chord_freqs = [root * 2, fifth * 2, root * 4]
        for step in range(8):
            step_time = bar_start + step * 0.5 * beat_dur
            s_idx = int(step_time * SAMPLE_RATE)
            note_f = chord_freqs[step % len(chord_freqs)]
            d_samps = int(0.25 * beat_dur * SAMPLE_RATE)
            for i in range(d_samps):
                pos = s_idx + i
                if pos < num_samples:
                    t = i / SAMPLE_RATE
                    env = math.exp(-14.0 * t)
                    val = 0.08 * math.sin(2 * math.pi * note_f * t) * env
                    samples[pos] += val

    # 4. Subtle percussion: Cozy hi-hat and rim click
    for beat in range(total_beats):
        b_time = beat * beat_dur
        # Hi-hat on every beat
        s_idx = int(b_time * SAMPLE_RATE)
        # 12ms noise tick
        d_hat = int(0.015 * SAMPLE_RATE)
        for i in range(d_hat):
            pos = s_idx + i
            if pos < num_samples:
                noise = ((hash(pos) % 1000) / 500.0 - 1.0)
                env = math.exp(-60.0 * (i / SAMPLE_RATE))
                samples[pos] += noise * env * 0.035

        # Rim click on beats 1 and 3 (2nd and 4th of each 4-beat bar)
        if beat % 2 == 1:
            d_rim = int(0.03 * SAMPLE_RATE)
            for i in range(d_rim):
                pos = s_idx + i
                if pos < num_samples:
                    t = i / SAMPLE_RATE
                    env = math.exp(-35.0 * t)
                    val = 0.08 * math.sin(2 * math.pi * 1400 * t) * env
                    samples[pos] += val

    # Normalize to -1.5 dB headroom (0.85 max amplitude)
    max_amp = max(abs(s) for s in samples) or 1.0
    return [0.82 * (s / max_amp) for s in samples]

def main():
    sfx_dir = r"C:\Users\john\git\club-budget-the-game-godot\assets\audio\sfx"
    music_dir = r"C:\Users\john\git\club-budget-the-game-godot\assets\audio\music"
    os.makedirs(sfx_dir, exist_ok=True)
    os.makedirs(music_dir, exist_ok=True)

    print("Generating SFX...")
    write_wav(os.path.join(sfx_dir, "select.wav"), gen_select())
    write_wav(os.path.join(sfx_dir, "confirm.wav"), gen_confirm())
    write_wav(os.path.join(sfx_dir, "cash.wav"), gen_cash())
    write_wav(os.path.join(sfx_dir, "alarm.wav"), gen_alarm())
    write_wav(os.path.join(sfx_dir, "correct.wav"), gen_correct())
    write_wav(os.path.join(sfx_dir, "game_over.wav"), gen_game_over())
    write_wav(os.path.join(sfx_dir, "victory.wav"), gen_victory())

    print("Generating Background Music...")
    write_wav(os.path.join(music_dir, "theme_music.wav"), gen_bg_music())
    print("Audio assets generated successfully!")

if __name__ == "__main__":
    main()
