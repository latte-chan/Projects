import os
import numpy as np
import argparse
import random
from colormath.color_objects import sRGBColor, LabColor
from colormath.color_conversions import convert_color
from colormath.color_diff import delta_e_cie1976
from PIL import Image

parser = argparse.ArgumentParser(description = 'Synthesize a texture.')
parser.add_argument('imagePath')
parser.add_argument('numInputBlocks', type = int)
parser.add_argument('overlap', type = int)
parser.add_argument('outputSize', type = int)

#parse all arguments from command line
args = parser.parse_args()

#open image and read its rgb values to array
image = Image.open(args.imagePath)
col,row = image.size
data = np.zeros((row, col, 3), dtype = np.uint8)
pixels = image.load()

#create output array to create image from
output = np.zeros((args.outputSize, args.outputSize, 3), dtype = np.uint8)

print('start')

for rw in range(row):
    for cl in range(col):
        r,g,b = pixels[rw, cl]
        data[rw, cl, 0] = r
        data[rw, cl, 1] = g
        data[rw, cl, 2] = b

blockWidth = int(row / args.numInputBlocks)
blockHeight = int(col / args.numInputBlocks)

dataRowBlocks = int(row / blockWidth)
dataColBlocks = int(col / blockHeight)

outputRowBlocks = int(args.outputSize / (blockWidth - args.overlap * 2))
outputColBlocks = int(args.outputSize / (blockHeight - args.overlap * 2))

for rb in range(outputRowBlocks):
    for cb in range(outputColBlocks):
        randBlock = [random.randint(0, dataRowBlocks - 1), random.randint(0, dataColBlocks - 1)]
        randBlockStart = [randBlock[0] * blockWidth, randBlock[1] * blockHeight]

        outputBlockStart = [rb * blockWidth, cb * blockHeight]

        if (rb > 0):
            outputBlockStart[0] = outputBlockStart[0] - rb * args.overlap
        if (cb > 0):
            outputBlockStart[1] = outputBlockStart[1] - cb * args.overlap

        #vertical overlap arrays
        prevVertOverlap = np.zeros((blockWidth, args.overlap, 3), dtype = np.uint8)
        nextVertOverlap = np.zeros((blockWidth, args.overlap, 3), dtype = np.uint8)
        diffVertOverlap = np.zeros((blockWidth, args.overlap), dtype = np.uint64)
        diffVertOverlapIndex = np.zeros(blockWidth, dtype = np.uint8)

        #horizontal overlap arrays
        prevHoriOverlap = np.zeros((args.overlap, blockWidth, 3), dtype = np.uint8)
        nextHoriOverlap = np.zeros((args.overlap, blockWidth, 3), dtype = np.uint8)
        diffHoriOverlap = np.zeros((args.overlap, blockWidth), dtype = np.uint64)
        diffHoriOverlapIndex = np.zeros(blockWidth, dtype = np.uint8)

        #store prev vertical overlap
        if (cb > 0):
            for rw in range(blockWidth):
                for cl in range(args.overlap):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        prevVertOverlap[rw, cl] = output[outputRw, outputCl]

        #store prev horizontal overlap
        if (rb > 0):
            for rw in range(args.overlap):
                for cl in range(blockWidth):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        prevHoriOverlap[rw, cl] = output[outputRw, outputCl]

        #add new block to output
        for rw in range(blockWidth):
            for cl in range(blockHeight):
                outputRw = outputBlockStart[0] + rw
                outputCl = outputBlockStart[1] + cl
                dataRw = randBlockStart[0] + rw
                dataCl = randBlockStart[1] + cl
                if(outputRw < args.outputSize and outputCl < args.outputSize):
                    output[outputRw, outputCl] = data[dataRw, dataCl]

        #store next vertical overlap
        if (cb > 0):
            for rw in range(blockWidth):
                for cl in range(args.overlap):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        nextVertOverlap[rw, cl] = output[outputRw, outputCl]

        #convert vertical rgb color space to lab color space
        if (cb > 0):
            for rw in range(blockWidth):
                for cl in range(args.overlap):
                    prevValues = prevVertOverlap[rw, cl]
                    nextValues = nextVertOverlap[rw, cl]
                    prevRGB = sRGBColor(prevValues[0], prevValues[1], prevValues[2])
                    nextRGB = sRGBColor(nextValues[0], nextValues[1], nextValues[2])
                    prevLab = convert_color(prevRGB, LabColor)
                    nextLab = convert_color(nextRGB, LabColor)
                    left = min(args.overlap-1, cl+1)
                    right = max(0, cl-1)
                    if (rw == 0):
                        diffVertOverlap[rw, cl] = delta_e_cie1976(prevLab, nextLab)
                    else:
                        diffVertOverlap[rw, cl] = delta_e_cie1976(prevLab, nextLab) + min(diffVertOverlap[rw-1, right], diffVertOverlap[rw-1, cl], diffVertOverlap[rw-1, left])


        #calculate vertical minimum boundary cut
        if (cb > 0):
            for rw in range(blockWidth - 1, 0, -1):
                row = diffVertOverlap[rw]
                if(rw == blockWidth - 1):
                    minValue = np.amin(row)
                else:
                    left = max(minIndex[0][0] - 1, 0)
                    right = min(minIndex[0][0] + 2, args.overlap)
                    minValue = np.amin(row[left:right])
                minIndex = np.where(row == minValue)
                diffVertOverlapIndex[blockWidth - 1 - rw] = minIndex[0][0]

        #add vertical overlap thats cut to minimum error
        if (cb > 0):
            for rw in range(blockWidth):
                for cl in range(args.overlap):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        if(cl < diffVertOverlapIndex[rw]):
                            output[outputRw, outputCl] = prevVertOverlap[rw, cl]
                        else:
                            output[outputRw, outputCl] = nextVertOverlap[rw, cl]

        #store next horizontal overlap
        if (rb > 0):
            for rw in range(args.overlap):
                for cl in range(blockWidth):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        nextHoriOverlap[rw, cl] = output[outputRw, outputCl]

        #convert horizontal rgb color space to lab color space
        if (rb > 0):
            for cl in range(blockWidth):
                for rw in range(args.overlap):
                    prevValues = prevHoriOverlap[rw, cl]
                    nextValues = nextHoriOverlap[rw, cl]
                    prevRGB = sRGBColor(prevValues[0], prevValues[1], prevValues[2])
                    nextRGB = sRGBColor(nextValues[0], nextValues[1], nextValues[2])
                    prevLab = convert_color(prevRGB, LabColor)
                    nextLab = convert_color(nextRGB, LabColor)
                    top = max(0, rw-1)
                    bottom = min(args.overlap-1, rw+1)
                    if (cl == 0):
                        diffHoriOverlap[rw, cl] = delta_e_cie1976(prevLab, nextLab)
                    else:
                        diffHoriOverlap[rw, cl] = delta_e_cie1976(prevLab, nextLab) + min(diffHoriOverlap[top, cl-1], diffHoriOverlap[rw, cl-1], diffHoriOverlap[bottom, cl-1])
        
        #calculate horizontal minimum boundary cut
        if (rb > 0):
            for cl in range(blockWidth - 1, 0, -1):
                row = []
                for rw in range(args.overlap):
                    row.append(diffHoriOverlap[rw, cl])
                if(cl == blockWidth - 1):
                    minValue = np.amin(row)
                else:
                    left = max(minIndex[0][0] - 1, 0)
                    right = min(minIndex[0][0] + 2, args.overlap)
                    minValue = np.amin(row[left:right])
                minIndex = np.where(row == minValue)
                diffHoriOverlapIndex[blockWidth - 1 - cl] = minIndex[0][0]

        #add horizontal overlap thats cut to minimum error
        if (rb > 0):
            for cl in range(blockWidth):
                for rw in range(args.overlap):
                    outputRw = outputBlockStart[0] + rw
                    outputCl = outputBlockStart[1] + cl
                    if(outputRw < args.outputSize and outputCl < args.outputSize):
                        if(rw < diffHoriOverlapIndex[cl]):
                            output[outputRw, outputCl] = prevHoriOverlap[rw, cl]
                        else:
                            output[outputRw, outputCl] = nextHoriOverlap[rw, cl]
        


#turn output array into image and save the output
outputImage = Image.fromarray(output, 'RGB')
outputImage.save('output.png')

print('done')