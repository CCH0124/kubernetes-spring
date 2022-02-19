package example.k8s.cch.k8sdemo.controller;

import java.net.Inet4Address;
import java.net.UnknownHostException;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
public class IpController {

    @Value("${COMMITHASH:}")
    private String LATEST_COMMIT_HASH;

    @Value("${COMMITLOG:}")
    private String LATEST_COMMIT_LOG;

    @GetMapping(value = "ipadd", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> getIpAdd() throws UnknownHostException {
        return ResponseEntity.ok(Map.of("ip", Inet4Address.getLocalHost().getHostAddress()));
    }

    @GetMapping(value = "hostname", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> getHostname() throws UnknownHostException {
        return ResponseEntity.ok(Map.of("ip", Inet4Address.getLocalHost().getHostName()));
    }

    @GetMapping(value = "gitLastHistory", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> getGitLastHistory() {
        return ResponseEntity.ok(Map.of("Latest_Commit", LATEST_COMMIT_HASH,"Latest_Log", LATEST_COMMIT_LOG));
    }
}
