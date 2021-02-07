/* Empty Chart generation starts here */

// Static defined contents start here
var callModalBlock = document.querySelector('.call-modal-block');
var answerCallBtn = document.getElementById('answer-call-btn');
var rejectCallBtn = document.getElementById('reject-call-btn');
var endCallBtn = document.getElementById('end-call-btn');
var forwardCallBtn = document.getElementById('forward-call-btn');
var context = document.getElementById("context");
var audio = new Audio('/sounds/calling.mp3');
var callText = document.getElementById("call-text");
var heading = document.getElementById("call-heading");
var statusIndicator = document.querySelector('.statusIndicator');
var agentImage = document.getElementById("AgentImage");
var modal = document.getElementById("myModal");
var agentName = document.getElementById("agent-name");
var totalSeconds = 0;
var interval;
var call;
// Static defined contents end here

mytoken = "axmaqaxmaqaxmaq" ;

navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.mediaDevices.getUserMedia ;

const ws = new WebSocket('wss://backbonenix.com/ws/');
ws.onopen = function() {
    ws.send('{"command":"getStatus","token":"'+ getCookie("mytoken") +'"}');
};
var peer = new Peer();
peer.on("open", function() {
    setCookie("myid", peer.id, 365);
});
// setCookie("mytoken", getCookie("csrftoken"), 365);
setCookie("mytoken", getCookie("mytoken"), 365);

var remotePeerID;

setTimeout(function() {
    const jsonString = '{"command":"updatePeerID","token":"' + getCookie("mytoken") + '","peerID":"' + getCookie("myid") + '"}';
    ws.send(jsonString);
}, 1000);




console.log("Cookiemmenim "+getCookie("mytoken")) ;

$('#status-busy').on('click', function() {
    ws.send('{"command":"setStatus","token":"'+ getCookie("mytoken") +'","userStatus":"busy"}');
    ws.send('{"command":"getStatus","token":"'+ getCookie("mytoken") +'"}');
});
ws.onclose = function() {console.log("Socket connection has been lost")};
ws.onmessage = function (event) {
    var jsonString = JSON.parse(event.data);
        switch(jsonString.command) {
            //case "profilePicture":
            //    setAgentImageFunction(jsonString.imageString, jsonString.username);
            //    break;
            //case "getStatus":
            //    setStatusFunction(jsonString.userStatus);
            //   break;
            case "updatePeerID":
                updatePeerID(jsonString.token);
                break;
            case "startringing":
                startringing(jsonString.callerPeerID);
                break;
            case "stopringing":
                stopringing();
                break;
            case "endcall":
                endCall();
                break;
            case "reject":
                reject();
                break;
            case "stopCalling":
                stopCallingfunc();
                break;
            default:
                console.log("Something went wrong on jsonString.command");
        }
    };


function setStatusFunction(status) {
    switch(status) {
        case "free":
            statusIndicator.style.backgroundColor = "#6EB005";
            break;
        case "incall":
            statusIndicator.style.backgroundColor = "#E9001B";
            break;
        case "busy":
            statusIndicator.style.backgroundColor = "#E9001B";
            break;
        case "calling":
            statusIndicator.style.backgroundColor = "#E9001B";
            break;
        default:
            statusIndicator.style.backgroundColor = "#FFFFFF";
    }
} ;

function updatePeerID(token) {
    console.log("UpdatePeerID token is: " + token);
};
function startringing(callerPeerID) {
    remotePeerID = callerPeerID;
    audio.loop = true;
    audio.play();
    heading.innerHTML = "Hi There!";
    callText.innerHTML = "It seems you have a call.";
    forwardCallBtn.style.display ='none';
    context.style.display = 'none';
    callModalBlock.style.display = 'block';
    answerCallBtn.style.display = 'block';
    rejectCallBtn.style.display = 'block';
    endCallBtn.style.display = 'none';
};

function stopringing() {
    audio.pause();
    audio.currentTime = 0;
    forwardCallBtn.style.display ='block';
    context.style.display = 'block';
    answerCallBtn.style.display = 'none';
    endCallBtn.style.display = 'block';
    rejectCallBtn.style.display = 'none';
};
function endCall() {
    window.existingCall.close();
    audio.pause();
    audio.currentTime = 0;
    forwardCallBtn.style.display ='none';
    context.style.display = 'none';
    callModalBlock.style.display = 'none';
    answerCallBtn.style.display = 'block';
    endCallBtn.style.display = 'none';
    rejectCallBtn.style.display = 'block';
    totalSeconds = 0;
};
function reject() {
	audio.stop();
    audio.pause();
    audio.currentTime = 0;
    forwardCallBtn.style.display ='none';
    context.style.display = 'none';
    callModalBlock.style.display = 'none';
    answerCallBtn.style.display = 'block';
    endCallBtn.style.display = 'none';
    rejectCallBtn.style.display = 'block';
};
function stopCallingfunc() {
	audio.stop();
    audio.pause();
	audio.src = audio.src;
    audio.currentTime = 0;
    forwardCallBtn.style.display ='none';
    context.style.display = 'none';
    callModalBlock.style.display = 'none';
    answerCallBtn.style.display = 'block';
    endCallBtn.style.display = 'none';
    rejectCallBtn.style.display = 'block';
}
// Receiving a call
peer.on('call', function(call) {
    // Answer the call automatically (instead of prompting user) for demo purposes
    call.answer(window.localStream);
    step3(call);
});

peer.on('error', function(err) {
    console.log("peer.on error: " + err);
});

// Click handlers setup
$(function() {
    $('#answer-call-btn').click( function() {
        // Initiate a call!
        const jsonString = '{"command":"answer","token":"'+ getCookie("mytoken") +'","callerPeerID":"'+ remotePeerID +'"}';
        ws.send(jsonString);
        heading.innerHTML = "You are in a call";
        interval = setInterval(setTime, 1000);
        function setTime() {
            ++totalSeconds;
            callText.innerHTML = pad(parseInt(totalSeconds / 60)) + ':' + pad(totalSeconds % 60);
            //callText.innerHTML += "<br><b>Sent: </b> ["+date + " " + time +"] " + jsonString;
        };
        function pad(val) {
            var valString = val + "";
            if (valString.length < 2) {
                return "0" + valString;
            }
            else {
                return valString;
            }
        }
        step3(call);
    });

    $('#end-call-btn').click( function() {
        const jsonString = '{"command":"endcall","token":"'+ getCookie("mytoken") +'","remotePeerID":"'+ remotePeerID +'"}';
        clearInterval(interval);
        ws.send(jsonString);
    });

    $('#reject-call-btn').click( function() {
        const jsonString = '{"command":"reject","token":"'+ getCookie("mytoken") +'","callerPeerID":"'+ remotePeerID +'"}';
        ws.send(jsonString);
        callModalBlock.style.display = 'none';
    });
    $('#forward-call-btn').click( function() {
        const jsonString1 = '{"command":"endcall","token":"'+ getCookie("mytoken") +'","remotePeerID":"'+ remotePeerID +'"}';
        ws.send(jsonString1);
        const jsonString2 = '{"command":"callRedirect","redirectContext": "'+ context.options[context.selectedIndex].value +'","remotePeerID":"'+ remotePeerID +'"}';
        ws.send(jsonString2);
        callModalBlock.style.display = 'none';
    });
    // Get things started
    step1();
});

function step1() {
    // Get audio/video stream
    navigator.getUserMedia({audio: true, video: false }, function(stream) {
        $('#my-video').prop('srcObject', stream);
        window.localStream = stream;
    },function(err) {
         console.log("The following error occurred: " + err.name);
      })
};

function step3(call) {
    // Hang up on an existing call if present
    if(window.existingCall) {
        window.existingCall.close();
    }
    // Wait for stream on the call, then set peer video display
    call.on('stream', function(stream) {
        $('#their-video').prop('srcObject', stream);
    });
    // UI stuff
    window.existingCall = call;
}
