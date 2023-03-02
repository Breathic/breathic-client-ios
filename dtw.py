import os
import argparse
import numpy as np
from pydub import AudioSegment

SAMPLING_RATE = 100
delimiter = '|'

def cut_time_series(array1, array2):
    length_array1 = len(array1)
    length_array2 = len(array2)
    if length_array1 < length_array2: # we have to clip the second series
        array2 = array2[:length_array1]
    else: # we have to clip the first series
        array1 = array1[:length_array2]
    return array1, array2

def euclidean_distance_calculator(array1, array2):
    clipped_array1, clipped_array2 = cut_time_series(array1, array2)
    assert len(clipped_array1) == len(clipped_array2), "Not equal length!"
    dist = np.linalg.norm(clipped_array1-clipped_array2)
    return round(dist, 2)

def load_audio_file(audio_path):
  audio = AudioSegment.from_file(audio_path)
  audio = audio.set_frame_rate(SAMPLING_RATE)
  samples = np.array(audio.get_array_of_samples())
  normalized_samples = samples / max(samples)
  return normalized_samples

def adjust_length(longer_array, shorter_array):
    """ Pad the smaller series in order to have the same length as the longer array
    :param longer_array: the longer of the two sequences
    :param shorter_array: the shorter of the two sequences
    :return: the padded shorter sequences, which now has the same length as the longer array
    """

    difference_in_length = len(longer_array) - len(shorter_array)
    padding_zeros = np.zeros(difference_in_length)
    adjusted_array = np.concatenate([shorter_array, padding_zeros])
    return adjusted_array

def dtwupd(a, b, r):
    """ Compute the DTW distance between 2 time series with a warping band constraint
    :param a: the time series array 1
    :param b: the time series array 2
    :param r: the size of Sakoe-Chiba warping band
    :return: the DTW distance
    """

    if len(a) < len(b):
        a = adjust_length(longer_array=b, shorter_array=a)
    else:
        b = adjust_length(longer_array=a, shorter_array=b)

    m = len(a)
    k = 0

    # Instead of using matrix of size O(m^2) or O(mr), we will reuse two arrays of size O(r)
    cost = [float('inf')] * (2 * r + 1)
    cost_prev = [float('inf')] * (2 * r + 1)

    for i in range(0, m):
        k = max(0, r - i)

        for j in range(max(0, i - r), min(m - 1, i + r) + 1):
            # Initialize all row and column
            if i == 0 and j == 0:
                c = a[0] - b[0]
                cost[k] = c * c

                k += 1
                continue

            y = float('inf') if j - 1 < 0 or k - 1 < 0 else cost[k - 1]
            x = float('inf') if i < 1 or k > 2 * r - 1 else cost_prev[k + 1]
            z = float('inf') if i < 1 or j < 1 else cost_prev[k]

            # Classic DTW calculation
            d = a[i] - b[j]
            cost[k] = min(x, y, z) + d * d

            k += 1

        # Move current array to previous array
        cost, cost_prev = cost_prev, cost

    # The DTW distance is in the last cell in the matrix of size O(m^2) or at the middle of our array
    k -= 1
    return cost_prev[k]

def read_file(filename):
    if os.path.exists(filename):
        f = open(filename, "r")
        out = ''.join(f.readlines())
        f.close()
        return out

def correlate(audiopath, source, target, extension, dtwpath):
  left = dtwpath + source + delimiter + target + '.dtw'
  out = read_file(left)
  if out:
    return float(out)

  right = dtwpath + target + delimiter + source + '.dtw'
  out = read_file(right)
  if out:
    return float(out)

  array1 = load_audio_file(audiopath + source + '.' + extension)
  array2 = load_audio_file(audiopath + target + '.' + extension)
  relative_warping_band = 5 / 100
  r = int(len(array1) * relative_warping_band)
  #euclidean_distance = euclidean_distance_calculator(array1, array2)
  dtw = dtwupd(array1, array2, r)

  if dtw:
    with open(left, 'w') as file:
        file.write(str(dtw))

  return dtw #euclidean_distance

def initialize():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i ", "--source-file", help="source file")
    parser.add_argument("-o ", "--target-file", help="target file")
    args = parser.parse_args()
  
    SOURCE_FILE = args.source_file if args.source_file else None
    TARGET_FILE = args.target_file if args.target_file else None
    if not SOURCE_FILE or not TARGET_FILE:
      raise Exception("Source or Target files not specified.")

    return SOURCE_FILE, TARGET_FILE
  
if __name__ == "__main__":
    FOLDER, SOURCE_FILE, TARGET_FILE = initialize()
    correlate(FOLDER, SOURCE_FILE, TARGET_FILE)

