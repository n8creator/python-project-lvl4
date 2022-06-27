from django.http import HttpResponse


def homePageView(request):
    return HttpResponse("Task Manager Start Page")
