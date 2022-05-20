%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (unsigned_div_rem, sqrt)
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts, finalize_keccak
from starkware.cairo.common.cairo_builtins import (HashBuiltin, BitwiseBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_only_token_owner,
    ERC721_setTokenURI
)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq, uint256_unsigned_div_rem
)
from openzeppelin.access.ownable import (
    Ownable_only_owner
)
from openzeppelin.token.erc721.library import _exists
from openzeppelin.utils.ShortString import uint256_to_ss
from openzeppelin.utils.Array import concat_arr
from openzeppelin.utils.constants import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)


@storage_var
func wizardNames( wizId : felt ) -> ( name : felt ):
end

@storage_var
func curr_index_storage() -> ( index : felt ):
end

@storage_var
func ERC721_base_tokenURI(index: felt) -> (res: felt):
end

@storage_var
func ERC721_base_tokenURI_len() -> (res: felt):
end

@constructor
func constructor { syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr }( name : felt, symbol : felt ):
    ERC721_initializer(name, symbol)
    return()
end


@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end


@view
func view_get_keccak_hash{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(salt : felt, value_to_hash : felt) -> (hashed_value : Uint256):
    alloc_locals
    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start
    # let (local keccak_ptr : felt*) = alloc()
    let (local arr : felt*) = alloc()
    assert arr[0] = salt
    assert arr[1] = value_to_hash
    let (hashed_value) = keccak_felts{keccak_ptr=keccak_ptr}(2, arr)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)
    return (hashed_value)
end

@external
func mintWiz { syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin* }( wizName : felt ):
    alloc_locals
    let (caller_address) = get_caller_address()
    let (curr_index) =curr_index_storage.read()
    let new_index = curr_index+1
    ERC721_mint(caller_address,Uint256(new_index,0))
    curr_index_storage.write(new_index)

    # get random stat
    let (block_number) = get_block_number()
    let (block_timestamp) = get_block_timestamp()
    let (stat) = view_get_keccak_hash(block_number,wizName)
    let (modulo_stat : Uint256,rem : Uint256) = uint256_unsigned_div_rem(stat,Uint256(100,0))
    let (modulo_test : Uint256,rem_test : Uint256) = uint256_unsigned_div_rem(Uint256(99,0),Uint256(10,0)) 
 
    return()
end


@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end

func ERC721_tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):
    alloc_locals

    let (exists) = _exists(token_id)
    assert exists = TRUE

    # Return tokenURI with an array of felts, `${base_tokenURI}/${token_id}`
    let (local base_tokenURI) = alloc()
    let (local base_tokenURI_len) = ERC721_base_tokenURI_len.read()
    _ERC721_baseTokenURI(base_tokenURI_len, base_tokenURI)
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id)
    let (tokenURI, tokenURI_len) = concat_arr(
        base_tokenURI_len,
        base_tokenURI,
        token_id_ss_len,
        token_id_ss,
    )

    return (tokenURI_len=tokenURI_len, tokenURI=tokenURI)
end


func _ERC721_baseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(base_tokenURI_len: felt, base_tokenURI: felt*):
    if base_tokenURI_len == 0:
        return ()
    end
    let (base) = ERC721_base_tokenURI.read(base_tokenURI_len)
    assert [base_tokenURI] = base
    _ERC721_baseTokenURI(base_tokenURI_len=base_tokenURI_len - 1, base_tokenURI=base_tokenURI + 1)
    return ()
end


func ERC721_setBaseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*):
    _ERC721_setBaseTokenURI(tokenURI_len, tokenURI)
    ERC721_base_tokenURI_len.write(tokenURI_len)
    return ()
end


func _ERC721_setBaseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*):
    if tokenURI_len == 0:
        return ()
    end
    ERC721_base_tokenURI.write(index=tokenURI_len, value=[tokenURI])
    _ERC721_setBaseTokenURI(tokenURI_len=tokenURI_len - 1, tokenURI=tokenURI + 1)
    return ()
end
