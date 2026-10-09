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
        # Clamp and pack samples
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
    # Crisp snappy UI tick
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
    # Two crisp rising tones
    t1 = gen_sine(587.33, 0.08, 25) # D5
    t2 = gen_sine(880.00, 0.12, 18) # A5
    return [0.6 * s for s in (t1 + t2)]

def gen_cash():
    # Metallic coin register ping
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env1 = math.exp(-12 * t)
        env2 = math.exp(-18 * t)
        # Harmonically rich coin frequencies
        val = (
            0.5 * math.sin(2 * math.pi * 987.77 * t) * env1 +
            0.35 * math.sin(2 * math.pi * 1975.53 * t) * env1 +
            0.25 * math.sin(2 * math.pi * 2637.02 * t) * env2
        )
        samples.append(val * 0.7)
    return samples

def gen_alarm():
    # Punchy alert buzzer
    duration = 0.3
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 380 - (150 * (t / duration)) # pitch drop
        env = math.exp(-6 * t)
        # Sawtooth / square rich tone
        val = 0.5 * math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
        samples.append(val * env * 0.8)
    return samples

def gen_correct():
    # Bright rising major arpeggio (C5 - E5 - G5 - C6)
    c5 = gen_sine(523.25, 0.07, 15)
    e5 = gen_sine(659.25, 0.07, 15)
    g5 = gen_sine(783.99, 0.07, 15)
    c6 = gen_sine(1046.50, 0.28, 8)
    return [0.65 * s for s in (c5 + e5 + g5 + c6)]

def gen_game_over():
    # Melancholy descending phrase
    c5 = gen_sine(523.25, 0.2, 8)
    b4 = gen_sine(493.88, 0.2, 8)
    a4 = gen_sine(440.00, 0.2, 8)
    ab4 = gen_sine(415.30, 0.25, 8)
    g4 = gen_sine(392.00, 0.45, 5)
    return [0.7 * s for s in (c5 + b4 + a4 + ab4 + g4)]

def gen_victory():
    # Triumphant fanfare: C5, E5, G5, G5, C6 sustain
    c5 = gen_sine(523.25, 0.12, 10)
    e5 = gen_sine(659.25, 0.12, 10)
    g5 = gen_sine(783.99, 0.14, 10)
    g5_2 = gen_sine(783.99, 0.10, 10)
    c6 = gen_sine(1046.50, 0.50, 4)
    return [0.75 * s for s in (c5 + e5 + g5 + g5_2 + c6)]

def gen_bg_music():
    # Cozy looping math club background theme (~12 seconds, 110 BPM)
    # Chord progression: Cmaj -> Gmaj -> Amin -> Fmaj
    bpm = 110.0
    beat_dur = 60.0 / bpm
    total_beats = 16
    total_duration = total_beats * beat_dur
    num_samples = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * num_samples

    # Bass notes per bar (2 beats each in our 8-bar loop)
    # C3, E3, G3, B3, A3, C4, F3, A3
    bass_notes = [
        (130.81, 0.0), (130.81, beat_dur),
        (196.00, 2*beat_dur), (196.00, 3*beat_dur),
        (220.00, 4*beat_dur), (220.00, 5*beat_dur),
        (174.61, 6*beat_dur), (174.61, 7*beat_dur),
        (130.81, 8*beat_dur), (130.81, 9*beat_dur),
        (196.00, 10*beat_dur), (196.00, 11*beat_dur),
        (220.00, 12*beat_dur), (220.00, 13*beat_dur),
        (174.61, 14*beat_dur), (196.00, 15*beat_dur),
    ]

    # Melody notes (cheerful playful math lead)
    # Frequencies: C5=523.25, D5=587.33, E5=659.25, G5=783.99, A5=880.00, C6=1046.50
    melody_notes = [
        (523.25, 0.0, 0.5), (659.25, 0.5*beat_dur, 0.5), (783.99, 1.0*beat_dur, 0.8), (659.25, 1.5*beat_dur, 0.4),
        (587.33, 2.0*beat_dur, 0.5), (783.99, 2.5*beat_dur, 0.5), (587.33, 3.0*beat_dur, 0.9),
        (440.00, 4.0*beat_dur, 0.5), (523.25, 4.5*beat_dur, 0.5), (659.25, 5.0*beat_dur, 0.8), (523.25, 5.5*beat_dur, 0.4),
        (587.33, 6.0*beat_dur, 0.5), (659.25, 6.5*beat_dur, 0.5), (523.25, 7.0*beat_dur, 0.9),

        (659.25, 8.0*beat_dur, 0.5), (783.99, 8.5*beat_dur, 0.5), (1046.50, 9.0*beat_dur, 0.8), (783.99, 9.5*beat_dur, 0.4),
        (880.00, 10.0*beat_dur, 0.5), (783.99, 10.5*beat_dur, 0.5), (587.33, 11.0*beat_dur, 0.9),
        (659.25, 12.0*beat_dur, 0.5), (783.99, 12.5*beat_dur, 0.5), (880.00, 13.0*beat_dur, 0.8), (659.25, 13.5*beat_dur, 0.4),
        (587.33, 14.0*beat_dur, 0.5), (493.88, 14.5*beat_dur, 0.5), (523.25, 15.0*beat_dur, 0.9),
    ]

    # Add bass
    for freq, start in bass_notes:
        start_idx = int(start * SAMPLE_RATE)
        dur_samples = int(beat_dur * 0.85 * SAMPLE_RATE)
        for i in range(dur_samples):
            idx = start_idx + i
            if idx < num_samples:
                t = i / SAMPLE_RATE
                env = math.exp(-4 * t)
                val = (0.2 * math.sin(2 * math.pi * freq * t) + 0.1 * math.sin(4 * math.pi * freq * t)) * env
                samples[idx] += val

    # Add melody
    for freq, start, length_beats in melody_notes:
        start_idx = int(start * SAMPLE_RATE)
        dur_samples = int(length_beats * beat_dur * 0.9 * SAMPLE_RATE)
        for i in range(dur_samples):
            idx = start_idx + i
            if idx < num_samples:
                t = i / SAMPLE_RATE
                env = math.exp(-5 * t)
                # Soft bell-like synth
                val = (0.25 * math.sin(2 * math.pi * freq * t) + 0.08 * math.sin(2 * math.pi * freq * 2 * t)) * env
                samples[idx] += val

    # Normalize volume
    max_amp = max(abs(s) for s in samples) or 1.0
    return [0.65 * (s / max_amp) for s in samples]

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
