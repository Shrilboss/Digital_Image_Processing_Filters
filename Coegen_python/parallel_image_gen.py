import numpy as np
import cv2
img = cv2.imread(r"path of out_gray.bmp")

a = np.zeros(img.shape)
for i in range(1, len(img)):
    for j in range(len(img[i])):
        for k in range(len(img[i][j])):
            a[i-1][j][k] = img[i][j][k]

cv2.imwrite("out_down.bmp", a)
            
a = np.zeros(img.shape)
for i in range(len(img)-1):
    for j in range(len(img[i])):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i+1][j][k] = img[i][j][k]

cv2.imwrite("out_up.bmp", a)


a = np.zeros(img.shape)
for i in range(len(img)):
    for j in range(1, len(img[i])):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i][j-1][k] = img[i][j][k]

cv2.imwrite("out_left.bmp", a)
            
a = np.zeros(img.shape)
for i in range(len(img)):
    for j in range(len(img[i])-1):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i][j+1][k] = img[i][j][k]

cv2.imwrite("out_right.bmp", a)


a = np.zeros(img.shape)
for i in range(1, len(img)):
    for j in range(1, len(img[i])):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i-1][j-1][k] = img[i][j][k]

cv2.imwrite("out_leftdown.bmp", a)

            
a = np.zeros(img.shape)
for i in range(len(img)-1):
    for j in range(len(img[i])-1):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i+1][j+1][k] = img[i][j][k]

cv2.imwrite("out_rightup.bmp", a)


a = np.zeros(img.shape)
for i in range(len(img)-1):
    for j in range(1, len(img[i])):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i+1][j-1][k] = img[i][j][k]

cv2.imwrite("out_leftup.bmp", a)
            
#shift 1 bit right
a = np.zeros(img.shape)
for i in range(1, len(img)):
    for j in range(len(img[i])-1):
        for k in range(len(img[i][j])):
            #print(img[i][j][k])
            a[i-1][j+1][k] = img[i][j][k]

cv2.imwrite("out_rightdown.bmp", a)


            