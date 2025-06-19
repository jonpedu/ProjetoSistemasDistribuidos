// Caminho: services/middleware-service/src/main/java/com/ufma/tap/middleware/dto/MessageDto.java
package com.ufma.tap.middleware.dto;

import com.ufma.tap.middleware.model.Message;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageDto {
    private String messageId;
    private String data;
    private String queue;
    private Date expireAt;

    public static MessageDto fromModel(Message message) {
        MessageDto dto = new MessageDto();
        dto.setMessageId(message.getMessageId());
        dto.setData(message.getData());
        dto.setQueue(message.getQueue());
        dto.setExpireAt(message.getExpireAt());
        return dto;
    }
}