const jitsiMeetBaseOptions = {

};

window.builldJitsiMeetOptions = function (options) {
    return {
        ...jitsiMeetBaseOptions,
        ...options
    };
}
