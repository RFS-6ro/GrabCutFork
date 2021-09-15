#pragma once

#include <opencv2/core/base.hpp>
#include <opencv2/core/mat.hpp>
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/imgcodecs.hpp"
#include "opencv2/highgui/highgui.hpp"


class CvFilters
{
public:
    static cv::Mat makeTransparent(cv::Mat img);
	static void applyGrabCut(cv::Mat * img, cv::Rect rect, cv::Mat * mask = nullptr);
	static void  cropContours(cv::Mat * img);
};

